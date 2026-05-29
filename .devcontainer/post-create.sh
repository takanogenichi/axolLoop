#!/bin/bash
set -e

echo "=== postCreateCommand 開始 ==="

# git 設定
git config --global --add safe.directory /workspace

# pnpm install（package.json が存在する場合）
if [ -f /workspace/package.json ]; then
  cd /workspace
  pnpm install
  echo "pnpm install 完了"
fi

# Prisma クライアント生成（schema が存在する場合）
if [ -f /workspace/prisma/schema.prisma ]; then
  cd /workspace
  pnpm exec prisma generate
  echo "Prisma クライアント生成完了"
fi

# Claude Code CLI インストール
if ! command -v claude &> /dev/null; then
  npm install -g @anthropic-ai/claude-code
  echo "Claude Code CLI インストール完了"
fi

# zsh をデフォルトシェルに設定
if [ -f ~/.zshrc ]; then
  echo 'export PATH="/workspace/node_modules/.bin:$PATH"' >> ~/.zshrc
fi

echo "=== postCreateCommand 完了 ==="
