#!/usr/bin/env bash
# bin/bedrock-refresh.sh — HOST で実行: SSO ログイン + Bedrock credentials ファイル生成
set -euo pipefail

CREDS_FILE="$HOME/.aws/credentials-bedrock"

# SSO セッションが有効か確認、期限切れなら再ログイン
if ! aws sts get-caller-identity --profile bedrock &>/dev/null; then
  echo "SSO セッション期限切れ。ブラウザ認証を開始します..."
  aws sso login --profile bedrock
fi

# credentials を解決
EXPORT_OUTPUT=$(aws configure export-credentials --profile bedrock --format env-no-export 2>&1) || {
  echo "ERROR: credentials の取得に失敗しました:" >&2
  echo "$EXPORT_OUTPUT" >&2
  echo "" >&2
  echo "確認事項:" >&2
  echo "  1. ~/.aws/config の [profile bedrock] の sso_role_name が正しいか" >&2
  echo "  2. IAM Identity Center で該当ロールが割り当てられているか" >&2
  echo "  3. aws sso login --profile bedrock を手動で再実行してみる" >&2
  exit 1
}
eval "$EXPORT_OUTPUT"

# DevContainer 用: credentials-bedrock ファイル ([default] セクション)
#
# 重要 (inode 固定対策):
#   このファイルは docker-compose.yml で「単一ファイル」として bind mount される。
#   単一ファイルの bind mount は「マウント時点の inode」に固定されるため、
#   rm / mv / エディタ保存などでファイルを作り直して inode が変わると、
#   コンテナ内の /home/vscode/.aws/credentials は古い内容のまま固定される。
#   → 必ず「既存ファイルを truncate して中身だけ上書き」し、inode を維持する。
[ -e "$CREDS_FILE" ] || touch "$CREDS_FILE"
printf '%s\n' \
  "[default]" \
  "aws_access_key_id=$AWS_ACCESS_KEY_ID" \
  "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" \
  "aws_session_token=$AWS_SESSION_TOKEN" \
  > "$CREDS_FILE"

# HOST 用: ~/.aws/credentials の [bedrock] セクションのみ更新
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile bedrock
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile bedrock
aws configure set aws_session_token "$AWS_SESSION_TOKEN" --profile bedrock

echo "✓ Bedrock credentials を更新しました (1h 有効)"
echo "  DevContainer 用: $CREDS_FILE"
echo "  HOST 用:         ~/.aws/credentials [bedrock] セクション"
