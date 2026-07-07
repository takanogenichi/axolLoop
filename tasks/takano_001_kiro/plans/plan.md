# kiro-cli & Claude Code を devContainer で「すぐ使える」状態にする 整備計画

## 1. 目的（task.md より）

devContainer を立ち上げたら、可能な限り単純な操作で kiro-cli と Claude Code をすぐ使えるようにする。

1. **SSO ログインの手間をなくす**: 対話入力（ログイン方法 / Start URL / Region）を撤廃し、ブラウザ承認のみにする
2. **デフォルトモデルを `claude-opus-4.8` にする**
3. **サンドボックス環境なので `trust-all-tools` で起動する**
4. **Claude Code も Bedrock 経由ですぐ使えるようにする**

起動方法は `kiro-cli` でも `make kiro` でもよい。整備対象は `.devcontainer` ディレクトリ周辺。

---

## 2. 本リポジトリ固有の差異（HireAxol29 PR #19 との違い）

| 項目 | HireAxol29 | 本リポジトリ (axolLoop) |
|---|---|---|
| 実行ユーザ | `root` | `vscode`（`devcontainer.json` の `remoteUser` を `node` → `vscode` に変更） |
| バイナリ配置 | `/root/.local/bin`（root なのでそのまま利用可） | install.sh が `/root/.local/bin` に配置 → vscode ユーザからは辿れない（700）ため **`/usr/local/bin` へ移動** |
| kiro 認証データ | `/root/.local/share/kiro-cli` | `/home/vscode/.local/share/kiro-cli` |
| 永続化 volume マウント先 | `/root/.local/share/kiro-cli` | `/home/vscode/.local/share/kiro-cli` |
| volume 名 | `kirocli-data` | `kirocli-data` |
| Claude Code 認証 | `${HOME}/.aws/credentials-bedrock:/root/.aws/credentials:ro` | `${HOME}/.aws/credentials-bedrock:/home/vscode/.aws/credentials:ro` |
| Claude 設定 | `./claude-settings.json:/root/.claude/settings.json` | `./claude-settings.json:/home/vscode/.claude/settings.json` |

---

## 3. 設計方針（4 本柱）

### 柱 A: モデル & trust をデフォルト agent で固定（kiro-cli）

`.devcontainer/kiro/axol-agent.json` に専用 agent 定義 JSON を置き、コンテナ起動時に global agent として配置 + デフォルト化。素の `kiro-cli` でも `make kiro` でも、常に `claude-opus-4.8` + 全ツール許可で立ち上がる。

### 柱 B: 認証を named volume で永続化（kiro-cli）

`/home/vscode/.local/share/kiro-cli` を Docker named volume `kirocli-data` にマウント。「Rebuild Container」では volume が残るため、**一度ログインすれば以後は再ログイン不要**（`make downv` で volume を消したときのみ再ログイン）。

### 柱 C: 簡単起動コマンド（kiro-cli）

`make kiro` で、未ログイン時のみ CLI フラグで Start URL / Region を指定して device flow ログインを走らせてから chat を起動。対話入力は一切なし。

### 柱 D: Claude Code の Bedrock 認証（Claude Code）

HOST 側で `make bedrock` を実行して Bedrock SSO credentials を取得し、bind mount でコンテナへ渡す。`claude-settings.json` で Bedrock モード・モデル・権限を設定。コンテナ内では `claude` コマンドを打つだけで即利用可能。

---

## 4. 具体的な変更内容（ファイル別）

### 4-1. 変更: `.devcontainer/devcontainer.json`

`remoteUser` を `node` → `vscode` に変更。

```jsonc
"remoteUser": "vscode",
```

### 4-2. 変更: `.devcontainer/Dockerfile`

`vscode` ユーザの作成と kiro-cli のインストールを追加。

```dockerfile
# vscode ユーザ作成（devcontainer の remoteUser に合わせる）
RUN groupadd -g 1000 vscode || true \
    && useradd -m -s /bin/bash -u 1000 -g 1000 vscode || true \
    && echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ── kiro-cli インストール ──
# install.sh は /root/.local/bin に配置するため、vscode ユーザ用に /usr/local/bin へ移動
ARG KIRO_CLI_VERSION=latest
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) kiroArch="x86_64" ;; \
      arm64) kiroArch="aarch64" ;; \
      *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    curl --proto '=https' --tlsv1.2 -fsSL \
      "https://desktop-release.q.us-east-1.amazonaws.com/${KIRO_CLI_VERSION}/kirocli-${kiroArch}-linux.zip" \
      -o /tmp/kirocli.zip; \
    unzip -q /tmp/kirocli.zip -d /tmp; \
    /tmp/kirocli/install.sh --no-confirm --force; \
    mv /root/.local/bin/kiro-cli /usr/local/bin/kiro-cli; \
    chmod 755 /usr/local/bin/kiro-cli; \
    rm -rf /tmp/kirocli /tmp/kirocli.zip
```

挿入位置: 既存の `USER node` ブロックを `USER vscode` に置き換える前（root 権限が必要）。

> 既存の `node` ユーザ向け oh-my-zsh や sudo 設定は `vscode` ユーザに付け替える。

### 4-3. 新規: `.devcontainer/kiro/axol-agent.json`

デフォルト agent 定義。

```json
{
  "name": "axol",
  "description": "axolLoop devContainer default agent (opus-4.8 / trust-all, sandbox前提)",
  "prompt": null,
  "mcpServers": {},
  "tools": ["*"],
  "toolAliases": {},
  "allowedTools": ["*"],
  "resources": [],
  "hooks": {},
  "toolsSettings": {},
  "includeMcpJson": true,
  "model": "claude-opus-4.8"
}
```

### 4-4. 新規: `.devcontainer/claude-settings.json`

Claude Code の Bedrock 設定。HireAxol29 と同等。

```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "true",
    "AWS_REGION": "ap-northeast-1",
    "ANTHROPIC_MODEL": "jp.anthropic.claude-opus-4-8",
    "ANTHROPIC_SMALL_FAST_MODEL": "jp.anthropic.claude-sonnet-4-6",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "jp.anthropic.claude-opus-4-8",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "jp.anthropic.claude-sonnet-4-6",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "jp.anthropic.claude-haiku-4-5-20251001-v1:0",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
    "IS_SANDBOX": "1"
  },
  "permissions": {
    "defaultMode": "bypassPermissions"
  }
}
```

### 4-5. 新規: `bin/bedrock-refresh.sh`

HOST 側で実行する Bedrock SSO credentials 取得スクリプト。

```bash
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
  exit 1
}
eval "$EXPORT_OUTPUT"

# DevContainer 用: credentials-bedrock ファイル ([default] セクション)
# inode 固定対策: truncate で上書き（bind mount の inode を保持）
[ -e "$CREDS_FILE" ] || touch "$CREDS_FILE"
printf '%s\n' \
  "[default]" \
  "aws_access_key_id=$AWS_ACCESS_KEY_ID" \
  "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" \
  "aws_session_token=$AWS_SESSION_TOKEN" \
  > "$CREDS_FILE"

echo "✓ Bedrock credentials を更新しました (1h 有効)"
echo "  DevContainer 用: $CREDS_FILE"
```

### 4-6. 変更: `.devcontainer/docker-compose.yml`

`al` サービスに volume マウントを追加。

```yaml
services:
  al:
    volumes:
      - ..:/workspace:cached
      # Claude Code: Bedrock credentials (make bedrock で生成)
      - ${HOME}/.aws/credentials-bedrock:/home/vscode/.aws/credentials:ro
      # Claude Code: 設定ファイル
      - ./claude-settings.json:/home/vscode/.claude/settings.json
      # kiro-cli: 認証トークン等を永続化 (再ビルド後も再ログイン不要)
      - kirocli-data:/home/vscode/.local/share/kiro-cli

# ファイル末尾の volumes: セクションに追記
volumes:
  kirocli-data:
```

### 4-7. 追記: `.devcontainer/post-start.sh`

kiro-cli の agent 設定を毎起動で同期。

```sh
# kiro-cli: デフォルト agent / モデル設定（サンドボックス前提で trust-all）
if command -v kiro-cli >/dev/null 2>&1; then
  mkdir -p ~/.kiro/agents
  cp /workspace/.devcontainer/kiro/axol-agent.json ~/.kiro/agents/axol.json
  kiro-cli settings chat.defaultModel claude-opus-4.8 >/dev/null 2>&1 || true
  kiro-cli agent set-default axol >/dev/null 2>&1 || true
fi
```

### 4-8. 追記: `Makefile`

`kiro` ターゲットと `bedrock` ターゲットを追加。

```makefile
# ======================================================================
# AI CLI (kiro-cli / Claude Code)
# ======================================================================
KIRO_IDP    ?= https://d-95674b0b93.awsapps.com/start
KIRO_REGION ?= ap-northeast-1
.PHONY: kiro bedrock

kiro: ## kiro-cli を起動 (未ログインなら自動でSSOログイン / opus-4.8 / trust-all)
	@kiro-cli whoami >/dev/null 2>&1 || \
		kiro-cli login --license pro --identity-provider $(KIRO_IDP) --region $(KIRO_REGION) --use-device-flow
	@kiro-cli chat --trust-all-tools

bedrock: ## Bedrock SSO ログイン & credentials 更新 (HOST 専用)
	@if [ -n "$$REMOTE_CONTAINERS" ]; then echo "devcontainer環境下では実施できません。"; exit 1; fi
	@bash bin/bedrock-refresh.sh
```

### 4-9. 変更: `.devcontainer/post-create.sh`

`vscode` ユーザ対応。既存の Claude Code インストールはそのまま活用。

> `node` ユーザ固有の記述（`~/.zshrc` への PATH 追記など）は `vscode` ユーザに読み替える。

---

## 5. 起動後のユーザ体験（Before / After）

### kiro-cli

| | Before | After |
|---|---|---|
| 初回ログイン | `kiro-cli login --use-device-flow` + 対話 3 入力 + ブラウザ承認 | `make kiro` → ブラウザ承認のみ（対話入力なし） |
| 2 回目以降（同一 volume） | 毎回ログイン | `make kiro` → そのまま起動（再ログイン不要） |
| モデル | 都度選択 / 既定 | 常に `claude-opus-4.8` |
| ツール許可 | 都度確認 | 常に全許可（trust-all） |

### Claude Code

| | Before | After |
|---|---|---|
| 認証 | 未設定（API キー手入力 or 使えない） | HOST で `make bedrock` → コンテナ内で `claude` 即利用可 |
| モデル | 未設定 | `jp.anthropic.claude-opus-4-8`（Bedrock cross-region） |
| 権限 | 都度確認 | `bypassPermissions`（サンドボックス前提） |

---

## 6. 検証手順

### kiro-cli

1. `.devcontainer` を変更後、「Rebuild Container」を実行
2. `whoami` → `vscode` が表示されること
3. `which kiro-cli` → `/usr/local/bin/kiro-cli` が表示されること
4. `kiro-cli agent list` に `axol` が表示され、デフォルト（`*`）になっていること
5. `make kiro` 実行 → 未ログインなら 1 度だけブラウザ承認 → chat 起動
6. 起動した chat がモデル `claude-opus-4.8`、ツール確認なし（trust-all）で動作すること
7. 一度ログイン後にコンテナを「Rebuild Container」→ `make kiro` が **再ログインなしで** 起動すること

### Claude Code

1. HOST で `make bedrock` 実行 → `~/.aws/credentials-bedrock` が生成されること
2. devContainer 内で `claude` 実行 → Bedrock 経由で即応答すること（ログイン画面にならない）
3. `claude` 起動時にモデルが `jp.anthropic.claude-opus-4-8` になっていること

---

## 7. 前提条件・注意事項

- HOST 側に AWS CLI v2 と `[profile bedrock]` の設定（`~/.aws/config`）が必要
- `make bedrock` は HOST 側で実行（devContainer 内では不可）
- SSO トークンは約 1 時間で期限切れ → Claude Code の利用前に HOST で `make bedrock` を再実行する運用
- kiro-cli の SSO トークンは device flow で更新（コンテナ内で `make kiro` が自動処理）
