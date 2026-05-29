# AXOL Loop（1on1 マネジメント支援システム）

AI を活用した 1on1 面談の品質向上・マネジメント評価支援システムです。

# 基本ルール

- **日本語**: すべての回答・コメント・PR・コミットメッセージは日本語で記述すること。
- **ブランチ保護**: main / master / deploy/* ブランチには絶対にコミット・マージしないこと。コードを変更する場合は必ず新しいブランチを作成する。
- **PR レビュー**: 「PRレビューをしてもらって」と言われた場合は [docs/ai/copilot-review-workflow.md](docs/ai/copilot-review-workflow.md) を参照。

# タスク管理（tasks/）

すべてのタスク管理は `tasks/` ディレクトリに集約する。

## ディレクトリ構造

```
tasks/
├── 001_XXXXX/
│   ├── task.md          # タスク原本（ユーザが作成）
│   ├── questions/       # 質問・回答のやりとり（エージェントが作成）
│   │   ├── 001_XXX.md
│   │   └── 002_XXX.md
│   └── plans/           # 実施計画（エージェントが作成）
│       └── plan.md
├── 002_YYYYY/
│   ├── task.md
│   ├── questions/
│   └── plans/
└── ...
```

## ワークフロー

1. **タスク作成**: ユーザが `tasks/{連番}_{名前}/task.md` を作成し、要望・依頼内容を記載する。
2. **作業開始指示**: ユーザが「tasks/001 の作業を開始しよう」等の指示を出す。
3. **質問・計画**: エージェントは対象タスクディレクトリ内に `questions/` と `plans/` を作成する。
    - 不明点は `questions/` にファイルを作成してユーザに確認する。
    - `plans/` に実施計画を作成する。
4. **やりとり**: ユーザとエージェントが questions/ と plans/ を通じて詳細を詰める。
5. **実施指示**: ユーザが「tasks/001 の plan を実施して」と指示を出して、**初めて**コード修正等の作業を行う。

## 質問のルール

- 質問ごとに `questions/` 配下にファイルを作成する（例: `questions/001_api設計の方針.md`）
- ユーザは同じファイル内に回答を記入する
- **未回答の質問がある間は、その関連作業を進めないこと**（推測で勝手に作業しない）
- 回答済みのファイルはそのまま履歴として残す

# 技術スタック

- **NestJS**（Node.js 20 LTS+ / TypeScript）
- **Nuxt 3**（Vue 3 + TypeScript）フロントエンド
- **Prisma** ORM / **MySQL 8**（Aurora MySQL 互換）
- **Redis 7**（BullMQ 非同期ジョブ + キャッシュ）
- **MinIO**（S3 互換ストレージ・ローカル開発用）
- Docker Compose による DevContainer 開発環境
- pnpm パッケージマネージャ

# コンテナ構成

| コンテナ | 用途 | DevContainer(inst.1) |
|---|---|---|
| `al` | Node.js 20（NestJS + Nuxt 3 メインアプリ） | `29001` |
| `aldb` | MySQL 8 | `29002` |
| `smtpal` | Mailpit（メール確認 Web UI） | `29003` |
| `s3altal` | MinIO（S3 エミュレータ Web UI） | `29004` |
| `alredis` | Redis 7（BullMQ + キャッシュ） | `29005` |

## DevContainer

DevContainer では `make setup` でインスタンス番号（1〜8）を指定し、ポートを `+10` ずつオフセットする。

| インスタンス | offset | al | aldb | smtpal | s3altal | alredis |
|---|---|---|---|---|---|---|
| 1 | 0 | 29001 | 29002 | 29003 | 29004 | 29005 |
| 2 | +10 | 29011 | 29012 | 29013 | 29014 | 29015 |
| 3 | +20 | 29021 | 29022 | 29023 | 29024 | 29025 |
| ... | ... | ... | ... | ... | ... | ... |
| 8 | +70 | 29071 | 29072 | 29073 | 29074 | 29075 |

セットアップ手順:

1. `make setup` → インスタンス番号を入力（`.env`、`.devcontainer/.env`、`socat-forwards.sh` が自動生成される）
2. VS Code で「Reopen in Container」を実行
3. HOST 側からのターミナルでのログインは `./devlogin`

# テスト

- `make test` で全テストを実行（Docker 内で実行される）
- `make lint` で ESLint 静的解析を実行
- `make typecheck` で TypeScript 型チェックを実行
- テストディレクトリ構成: `tests/unit/`、`tests/integration/`、`tests/e2e/`

# ドキュメント

| ドキュメント | 内容 |
|---|---|
| [アーキテクチャガイド](docs/ai/architecture-guide.md) | リポジトリ構成・コンテナ構成・ディレクトリ構造 |
| [コマンドガイド](docs/ai/command-guide.md) | Make コマンド・テスト実行・コンテナログイン |
| [PR ガイド](docs/ai/pr-guide.md) | ブランチ命名規則・PR 管理 |
| [レビューガイド](docs/ai/review-guide.md) | レビュー方針・prefix・優先確認箇所 |
| [PR レビューワークフロー](docs/ai/copilot-review-workflow.md) | Copilot + gh CLI を使った PR レビュー手順 |
| [仕様書](docs/) | 機能設計、MQ スコアリング、音声処理、DB 設計等 |
