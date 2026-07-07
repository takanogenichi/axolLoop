# やりたいこと

- DevContainer を立ち上げたら、可能な限り単純な操作で kiro-cli（AI CLI）をすぐ使えるようにしたい。
- claudeコードもつかえるようにしたい。
- SSO ログイン時の対話入力（ログイン方法 / Start URL / Region）を撤廃したい。
- デフォルトで `claude-opus-4.8` モデルで起動させたい。
- DevContainer（サンドボックス環境）での起動なので `trust-all-tools` で起動したい。
- 起動方法は `kiro-cli` でも `make kiro` でもよい。整備対象は `.devcontainer` 周辺。

## 参照

- 兄弟リポジトリ HireAxol29 の PR #19（`update: kiro対応`）の内容に沿って、本リポジトリ（AxolConvertV3）でも同等に実装する。
  - https://github.com/tapweb/HireAxol29/pull/19

## 本リポジトリ固有の差異（適用時の調整点）

- 実行ユーザは vscode。install.sh は root 実行時 `/root/.local/bin`（700 で vscode から辿れない）に置くため、バイナリは `/usr/local/bin` へ移動する。認証データは `/home/vscode/.local/share/kiro-cli`。
- 認証永続化 volume 名は `kirocli-data`。
