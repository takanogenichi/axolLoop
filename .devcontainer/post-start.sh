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

echo "=== postStartCommand 完了 ==="
