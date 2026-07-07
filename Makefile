.PHONY: help setup init downv reset_db \
       dev build test lint lint-fix prisma-generate prisma-migrate prisma-studio \
       db redis minio \
       kiro bedrock \
       logd install update

# デフォルトターゲット
.DEFAULT_GOAL := help

##@ ヘルプ
help: ## コマンド一覧を表示
	@echo ""
	@echo "axolLoop - Make コマンド一覧"
	@echo "=============================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

##@ セットアップ（HOST で実行）
setup: ## DevContainer 用セットアップ（初回のみ・HOST で実行）
	@bash .devcontainer/setup.sh

downv: ## DevContainer の Docker 停止＆ボリューム削除（HOST で実行）
	@cd .devcontainer && docker compose down -v
	@echo "Docker 停止＆ボリューム削除完了"

reset_db: ## DB のみリセット（HOST で実行）
	@cd .devcontainer && docker compose stop aldb
	@cd .devcontainer && docker compose rm -f aldb
	@docker volume rm -f $$(docker volume ls -q | grep aldb-data) 2>/dev/null || true
	@cd .devcontainer && docker compose up -d aldb
	@echo "DB リセット完了。prisma migrate を実行してください"

##@ 初期化（app コンテナ内で実行）
init: ## プロジェクト初期化（pnpm install → prisma generate → prisma migrate）
	@pnpm install
	@if [ -f prisma/schema.prisma ]; then \
		pnpm exec prisma generate; \
		pnpm exec prisma migrate dev; \
	fi
	@echo "初期化完了"

##@ 開発（app コンテナ内で実行）
dev: ## 開発サーバー起動（NestJS + Nuxt）
	@pnpm run dev

build: ## プロダクションビルド
	@pnpm run build

##@ テスト・静的解析（app コンテナ内で実行）
test: ## テスト実行
	@pnpm run test

test-watch: ## テスト実行（ウォッチモード）
	@pnpm run test:watch

test-cov: ## テスト実行（カバレッジ付き）
	@pnpm run test:cov

lint: ## ESLint 実行
	@pnpm run lint

lint-fix: ## ESLint 自動修正
	@pnpm run lint:fix

format: ## Prettier フォーマット
	@pnpm run format

typecheck: ## TypeScript 型チェック
	@pnpm run typecheck

##@ Prisma（app コンテナ内で実行）
prisma-generate: ## Prisma クライアント生成
	@pnpm exec prisma generate

prisma-migrate: ## Prisma マイグレーション実行（dev）
	@pnpm exec prisma migrate dev

prisma-migrate-create: ## Prisma マイグレーション作成（名前を引数で指定: make prisma-migrate-create NAME=xxx）
	@pnpm exec prisma migrate dev --name $(NAME)

prisma-studio: ## Prisma Studio 起動（DB GUI）
	@pnpm exec prisma studio

prisma-seed: ## Prisma シードデータ投入
	@pnpm exec prisma db seed

##@ コンテナログイン（app コンテナ内で実行）
db: ## MySQL コンテナにログイン
	@mysql -h aldb -u axolloop -paxolloop axolloop

redis: ## Redis コンテナにログイン
	@redis-cli -h alredis

minio: ## MinIO コンテナにログイン
	@docker exec -it s3altal-$$(grep -E '^INSTANCE=' .devcontainer/.env 2>/dev/null | cut -d= -f2 || echo 1) sh

##@ AI CLI (kiro-cli / Claude Code)
KIRO_IDP    ?= https://d-95674b0b93.awsapps.com/start
KIRO_REGION ?= ap-northeast-1

kiro: ## kiro-cli を起動 (未ログインなら自動でSSOログイン / opus-4.8 / trust-all)
	@kiro-cli whoami >/dev/null 2>&1 || \
		kiro-cli login --license pro --identity-provider $(KIRO_IDP) --region $(KIRO_REGION) --use-device-flow
	@kiro-cli chat --trust-all-tools

bedrock: ## Bedrock SSO ログイン & credentials 更新 (HOST 専用)
	@if [ -n "$$REMOTE_CONTAINERS" ]; then echo "devcontainer環境下では実施できません。"; exit 1; fi
	@bash bin/bedrock-refresh.sh

##@ その他
logd: ## Docker Compose ログを tail
	@cd .devcontainer && docker compose logs -f

install: ## pnpm install
	@pnpm install

update: ## pnpm update
	@pnpm update
