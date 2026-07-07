#!/bin/bash
set -e

echo "=== postStartCommand 開始 ==="

# socat ポートフォワード起動
if [ -f /workspace/.devcontainer/socat-forwards.sh ]; then
  sudo bash /workspace/.devcontainer/socat-forwards.sh
fi

# MinIO バケット初期化
echo "MinIO バケット初期化中..."
for i in {1..30}; do
  if mc alias set local http://s3altal:9000 minioadmin minioadmin 2>/dev/null; then
    break
  fi
  sleep 1
done

# バケットが存在しない場合は作成
if ! mc ls local/axolloop 2>/dev/null; then
  mc mb local/axolloop
  echo "MinIO バケット 'axolloop' 作成完了"
fi

# kiro-cli: volume の所有権修正 + デフォルト agent / モデル設定
if command -v kiro-cli >/dev/null 2>&1; then
  # Docker volume は root で作成されるため所有権を修正
  sudo chown -R vscode:vscode ~/.local/share/kiro-cli 2>/dev/null || true
  mkdir -p ~/.kiro/agents
  cp /workspace/.devcontainer/kiro/axol-agent.json ~/.kiro/agents/axol.json
  kiro-cli settings chat.defaultModel claude-opus-4.8 >/dev/null 2>&1 || true
  kiro-cli agent set-default axol >/dev/null 2>&1 || true
fi

echo "=== postStartCommand 完了 ==="
