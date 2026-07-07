# UI モックアップ確認手順

## 前提

- DevContainer が起動していること
- app コンテナ内で作業すること（`./devlogin` でログイン）

## 手順

app コンテナ内で以下を実行:

```bash
npx http-server /workspace/docs -p 3000
```

ブラウザで以下にアクセス:

```
http://localhost:29001/ui-mockup.html
```

※ インスタンス2以降の場合はポートが `+10` ずつオフセットされます（例: インスタンス2 → `29011`）

## 停止

ターミナルで `Ctrl+C` でサーバーを停止。
