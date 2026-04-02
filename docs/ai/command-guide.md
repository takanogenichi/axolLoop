## 開発環境コマンド

開発はすべてDocker経由で行います。以下のMakefileコマンドを使用してください：

### Docker管理
- `make init` - git clone後の開発環境初期化（down、up、.env作成、composer install、key生成）
- `make up` - Dockerコンテナを起動
- `make down` - Dockerコンテナを停止
- `make downv` - コンテナを停止しボリュームを削除
- `make php` - ac3コンテナにユーザーとしてログイン（メイン開発コンテナ）
- `make phproot` - ac3コンテナにrootとしてログイン

### データベース操作
- `make init_db` - シーダーとマイグレーションによるデータベース初期化
- `make dockerbuild_db` - 最新データでMySQLのDockerイメージを再ビルド

### テストとコード品質
- `make test` - PHPUnitテストを実行（`vendor/bin/phpunit -c phpunit.xml tests`）
- `make stan` - ベースライン付きでPHPStan静的解析を実行（`vendor/bin/phpstan analyse --configuration=phpstan/phpstan.neon --memory-limit=2G`）
- `make stan_baseline` - 新しいPHPStanベースラインを生成
- `make stan_all` - ベースライン除外なしでPHPStanを実行

### 開発ユーティリティ
- `make update` - IDEヘルパーを生成（`php artisan ide-helper:generate` および `php artisan ide-helper:meta`）
- `make composerinstall` - Composer依存パッケージをインストール
- `make composerupdate` - Composer依存パッケージを更新

### ログと監視
- `make logd` - Docker composeログをフォロー
- `make logl` - Laravelアプリケーションログをフォロー
- `make logm` - PHPエラーログをフォロー
