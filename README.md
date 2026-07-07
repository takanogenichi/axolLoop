# axolLoop

AI を活用した 1on1 面談の品質向上・マネジメント評価支援システムです。

## 技術スタック

- NestJS（Node.js 20 LTS+ / TypeScript）/ Nuxt 3（Vue 3）/ MySQL 8
- Docker Compose による DevContainer 開発環境
- Prisma ORM、ESLint + Prettier、Vitest
- Redis 7（BullMQ 非同期ジョブ + キャッシュ）、MinIO（S3 互換ストレージ）

## コンテナ構成

| コンテナ | 用途 | DevContainer(inst.1) |
|---|---|---|
| `al-{N}` | Node.js 20（NestJS + Nuxt 3 メインアプリ） | `29001` |
| `aldb-{N}` | MySQL 8 | `29002` |
| `smtpal-{N}` | Mailpit（メール確認 Web UI） | `29003` |
| `s3altal-{N}` | MinIO（S3 エミュレータ Web UI） | `29004` |
| `alredis-{N}` | Redis 7（BullMQ + キャッシュ） | `29005` |

---

## セットアップ

### DevContainer

DevContainer を使うと、VS Code から統一された開発環境を利用できます。
複数環境を同時に立ち上げる場合は、インスタンス番号でポートを自動オフセットします。

#### 前提条件

- Docker Desktop
- VS Code + [Dev Containers 拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

#### 初期セットアップ

```bash
# 1. clone
git clone git@github.com:tapweb/axolLoop.git axolLoop-1
cd axolLoop-1

# 2. セットアップ（インスタンス番号を聞かれるので 1〜8 を入力）
make setup
```

`make setup` を実行すると以下が自動生成されます:

| 生成ファイル | 内容 |
|---|---|
| `.env` | アプリ用環境変数（ポート反映済） |
| `.devcontainer/.env` | docker-compose 用ポート変数 |
| `.devcontainer/socat-forwards.sh` | app コンテナ内ポートフォワード設定 |

#### ポートオフセット

インスタンス番号に応じてポートが `+10` ずつオフセットされます。
複数人が同じホストで開発する場合や、複数ブランチを同時に立ち上げる場合に便利です。

| インスタンス | offset | al | aldb | smtpal | s3altal | alredis |
|---|---|---|---|---|---|---|
| 1 | 0 | 29001 | 29002 | 29003 | 29004 | 29005 |
| 2 | +10 | 29011 | 29012 | 29013 | 29014 | 29015 |
| 3 | +20 | 29021 | 29022 | 29023 | 29024 | 29025 |
| 4 | +30 | 29031 | 29032 | 29033 | 29034 | 29035 |
| ... | ... | ... | ... | ... | ... | ... |
| 8 | +70 | 29071 | 29072 | 29073 | 29074 | 29075 |

#### DevContainer の起動

```bash
# 3. VS Code で開き、「Reopen in Container」を実行
code .
# → コマンドパレット > "Dev Containers: Reopen in Container"
```

#### ターミナルからのログイン

```bash
# ホストマシンから DevContainer の app コンテナにログイン
./devlogin
```

- VS Code で DevContainer を起動した状態で `./devlogin` を実行すると、app コンテナに zsh でログインできます。
- Claude Code を使う場合は `./devlogin` したシェル内で実行してください。DevContainer 内だけで動作するため、よりセキュアに利用できます。

起動時に以下が自動実行されます:

- `postCreateCommand`: git 設定、pnpm install、Prisma クライアント生成、Claude Code CLI インストール、zsh 設定
- `postStartCommand`: socat ポートフォワード起動、MinIO バケット初期化

---

## Make コマンド

`make help` で全コマンドを確認できます。

### 共通

| コマンド | 実行場所 | 説明 |
|---|---|---|
| `make help` | どちらでも | コマンド一覧を表示 |
| `make setup` | **HOST** | DevContainer 用セットアップ（初回のみ） |

### 初期化・Docker 操作

| コマンド | 実行場所 | 説明 |
|---|---|---|
| `make init` | app コンテナ | プロジェクト初期化（pnpm install → prisma generate → prisma migrate） |
| `make downv` | **HOST** | DevContainer の Docker 停止＆ボリューム削除 |
| `make reset_db` | **HOST** | DB のみリセット（stop → rm → volume 削除 → up） |

### 開発

| コマンド | 実行場所 | 説明 |
|---|---|---|
| `make dev` | app コンテナ | 開発サーバー起動（NestJS + Nuxt） |
| `make build` | app コンテナ | プロダクションビルド |

### テスト・静的解析

| コマンド | 実行場所 | 説明 |
|---|---|---|
| `make test` | app コンテナ | テスト実行 |
| `make test-watch` | app コンテナ | テスト実行（ウォッチモード） |
| `make test-cov` | app コンテナ | テスト実行（カバレッジ付き） |
| `make lint` | app コンテナ | ESLint 実行 |
| `make lint-fix` | app コンテナ | ESLint 自動修正 |
| `make format` | app コンテナ | Prettier フォーマット |
| `make typecheck` | app コンテナ | TypeScript 型チェック |

### Prisma

| コマンド | 実行場所 | 説明 |
|---|---|---|
| `make prisma-generate` | app コンテナ | Prisma クライアント生成 |
| `make prisma-migrate` | app コンテナ | Prisma マイグレーション実行（dev） |
| `make prisma-migrate-create` | app コンテナ | マイグレーション作成（`NAME=xxx` を指定） |
| `make prisma-studio` | app コンテナ | Prisma Studio 起動（DB GUI） |
| `make prisma-seed` | app コンテナ | シードデータ投入 |

### コンテナログイン

| コマンド | 実行場所 | 説明 |
|---|---|---|
| `make db` | app コンテナ | MySQL コンテナにログイン |
| `make redis` | app コンテナ | Redis コンテナにログイン |

### その他

| コマンド | 実行場所 | 説明 |
|---|---|---|
| `make logd` | どちらでも | Docker Compose ログを tail |
| `make install` | app コンテナ | pnpm install |
| `make update` | app コンテナ | pnpm update |

---

## ディレクトリ構成

```
axolLoop/
├── .devcontainer/          # DevContainer 設定
│   ├── devcontainer.json   # DevContainer 定義
│   ├── docker-compose.yml  # DevContainer 用コンテナ構成
│   ├── Dockerfile          # 開発コンテナイメージ
│   ├── setup.sh            # make setup のメインスクリプト
│   ├── post-create.sh      # コンテナ作成後スクリプト
│   ├── post-start.sh       # コンテナ起動後スクリプト
│   ├── .env.tpl            # .env テンプレート
│   └── socat-forwards.sh.tpl # socat テンプレート
├── docker/                 # Docker 関連設定
│   └── database/           # MySQL 設定
│       └── my.cnf
├── prisma/                 # Prisma スキーマ・マイグレーション
├── src/                    # NestJS バックエンド
├── frontend/               # Nuxt 3 フロントエンド
├── tests/                  # テスト
├── docs/                   # 仕様書・設計ドキュメント
├── devlogin                # HOST → app コンテナログイン用スクリプト
├── Makefile                # Make コマンド
└── ...
```

---

## ドキュメント

| ドキュメント | 内容 |
|---|---|
| [AGENTS.md](AGENTS.md) | AI エージェント向けルール・ガイドライン |
| [概要・機能設計](docs/01_概要・機能設計.md) | システム概要と機能設計 |
| [MQ スコアリング](docs/02_MQスコアリング.md) | マネジメント品質スコアリング仕様 |
| [音声データ処理](docs/04_音声データ処理.md) | 音声書き起こし・話者分離仕様 |
| [データベース設計](docs/05_データベース設計.md) | DB スキーマ設計 |
| [開発・運用計画](docs/06_開発・運用計画.md) | フェーズ別ロードマップ・技術スタック |
