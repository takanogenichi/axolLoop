# AXOLコンバートシステム（Axol28以降）

このレポジトリは、Mynavi/Airwork/CareerTasuからクローリングまたはAPIによって応募者のCSVをダウンロードし、それをアクセスオンラインに投入するシステムです

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

- **PHP 8.4** / **Laravel 12** / **MySQL 8**
- Docker Compose によるローカル開発環境
- PHPStan レベル6（ベースライン付き）、PHPUnit 11
- SQS キュー（ローカルは SQSエミュレータ）、S3 ストレージ（ローカルは S3エミュレータ）

# コンテナ構成

## 独立コンテナ（従来方式）

| コンテナ | 用途 | ポート |
|---|---|---|
| `ac3` | PHP 8.4 + Apache（メイン開発コンテナ） | `28991` |
| `ac3db` | MySQL 8 | `28992` |
| `smtpac3` | Mailpit（メール確認） | `28993`（Web UI） |
| `s3altac3` | S3エミュレータ | `28994`（Web UI） |
| `sqsac3` | SQSエミュレータ | `28995`（Web UI） |
| `tfliteac3` | tflite（Terraform Lite） | − |

セットアップ: `make init`

## DevContainer

DevContainer では `make setup` でインスタンス番号（1〜8）を指定し、ポートを `+10` ずつオフセットする。

| インスタンス | offset | ac3 | ac3db | smtpac3 | s3altac3 | sqsac3 |
|---|---|---|---|---|---|---|
| 1 | 0 | 28901 | 28902 | 28903 | 28904 | 28905 |
| 2 | +10 | 28911 | 28912 | 28913 | 28914 | 28915 |
| 3 | +20 | 28921 | 28922 | 28923 | 28924 | 28925 |
| ... | ... | ... | ... | ... | ... | ... |

セットアップ手順:

1. `make setup` → インスタンス番号を入力（`.env`、`.devcontainer/.env`、`socat-forwards.sh` が自動生成される）
2. VS Code で「Reopen in Container」を実行
3. HOST側からのターミナルでのログインは `./devlogin`

# テスト

- `make test` で全テストを実行（Docker内で実行される）
- `make stan` でPHPStan静的解析を実行
- テストメソッド名には `test01_01` のような連番プレフィクスを付与する
- DB接続が必要なテストは `tests/TestUtil/TestCaseAbstract.php` を継承する（`DatabaseTransactions` トレイト付き）
- テストディレクトリ構成: `tests/Unit/`、`tests/Feature/`、`tests/Commands/`、`tests/Service/`
- `pre-push` gitフックでPHPStanが自動実行される（`make init_hook` で初期化）

# ドキュメント

| ドキュメント | 内容 |
|---|---|
| [アーキテクチャガイド](docs/ai/architecture-guide.md) | リポジトリ構成・コンテナ構成・ディレクトリ構造 |
| [コマンドガイド](docs/ai/command-guide.md) | Make コマンド・テスト実行・コンテナログイン |
| [PHPコーディングガイド](docs/ai/php-coding-guide.md) | コーディング規約・Laravel-Data実装ルール |
| [PRガイド](docs/ai/pr-guide.md) | ブランチ命名規則・PR管理 |
| [レビューガイド](docs/ai/review-guide.md) | レビュー方針・prefix・優先確認箇所 |
| [PRレビューワークフロー](docs/ai/copilot-review-workflow.md) | Copilot + gh CLI を使ったPRレビュー手順 |
| [仕様書](docs/specs/) | 同一人物判定、セミナー重複、エアワーク同日除外等の仕様 |
