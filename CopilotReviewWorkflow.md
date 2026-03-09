# Copilot PR レビューワークフロー

Claude Code + GitHub Copilot を使った PR レビューの手順をまとめる。

## 前提

- `gh` CLI がインストール・認証済みであること
- リポジトリの Copilot Code Review が有効であること

## 1. ブランチ作成・実装・push

```bash
git checkout -b feature/xxx
# 実装作業
git add <files>
git commit -m "メッセージ"
git push -u origin feature/xxx
```

## 2. PR 作成

```bash
gh pr create --title "PR タイトル" --body "$(cat <<'EOF'
## Summary
- 変更内容

## Test plan
- [ ] テスト項目

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)" --base main
```

## 3. Copilot にレビュー依頼

**重要**: `gh pr edit --add-reviewer` では Copilot を追加できない。REST API で `copilot-pull-request-reviewer[bot]` を指定する必要がある。

**注意**: zsh では `[bot]` がグロブ展開されるため、`printf` を使うこと（`echo` だとシェル設定次第で崩れやすい）。

```bash
printf '{"reviewers":["copilot-pull-request-reviewer[bot]"]}' | \
  gh api repos/takanogenichi/axolLoop/pulls/<PR番号>/requested_reviewers \
  -X POST --input - --jq '.requested_reviewers[].login'
# → "Copilot" と表示されれば OK
```

### レビュアー追加の確認

```bash
gh api repos/takanogenichi/axolLoop/pulls/<PR番号>/requested_reviewers \
  --jq '.users[].login'
# → "Copilot" と表示されれば OK
# → レビュー完了後は空になる
```

## 4. レビュー結果の確認

Copilot のレビューが届くまで数分かかる場合がある。

### レビュー概要の確認

```bash
# 最新のレビューを確認
gh api repos/takanogenichi/axolLoop/pulls/<PR番号>/reviews \
  --jq '.[-1] | {user: .user.login, state: .state, body: .body}'
```

### コメント詳細の確認

```bash
gh api repos/takanogenichi/axolLoop/pulls/<PR番号>/comments \
  --jq '.[] | {id: .id, path: .path, line: .line, body: .body}'
```

### レビュー件数で再レビュー到着を確認

```bash
# レビュー件数を確認（再レビュー依頼のたびに増える）
gh api repos/takanogenichi/axolLoop/pulls/<PR番号>/reviews \
  --jq 'length'
```

## 5. 指摘の修正・push

指摘内容を深く吟味して、できる限り Copilot の意見を採用し、コードを修正し、コミット・push する。
無関係なところの指摘の場合は、今回修正するかどうかをユーザに聞いて修正するかどうか決める。
レビュー内容を不採用にする場合は、Copilot にその旨が伝わるように該当ソースコードに不採用にした理由をコメントで記載する。

```bash
git add <修正ファイル>
git commit -m "fix: Copilot レビュー指摘対応"
git push
```

## 6. 解決済みスレッドを Resolve

### スレッド ID 一覧の取得

```bash
gh api graphql -f query='
{
  repository(owner: "takanogenichi", name: "axolLoop") {
    pullRequest(number: <PR番号>) {
      reviewThreads(first: 20) {
        nodes {
          id
          isResolved
          comments(first: 1) {
            nodes {
              body
              path
            }
          }
        }
      }
    }
  }
}'
```

### スレッドの Resolve

```bash
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "<スレッド ID>"}) {
    thread { isResolved }
  }
}'
```

### 複数スレッドを一括 Resolve

```bash
for thread_id in <ID1> <ID2> <ID3>; do
  gh api graphql -f query="
mutation {
  resolveReviewThread(input: {threadId: \"${thread_id}\"}) {
    thread { isResolved }
  }
}" --jq '.data.resolveReviewThread.thread.isResolved'
done
```

## 7. Copilot に再レビュー依頼

Step 3 と同じコマンドで再度レビュー依頼する。

```bash
printf '{"reviewers":["copilot-pull-request-reviewer[bot]"]}' | \
  gh api repos/takanogenichi/axolLoop/pulls/<PR番号>/requested_reviewers \
  -X POST --input - --jq '.requested_reviewers[].login'
```

## 8. 指摘がなくなるまで 4〜7 を繰り返す

## 補足

### タイミングに関する注意

- Copilot のレビューが届くまで数分かかる場合がある
- **レビュー到着の確認は必ず `reviews` の件数で行う**。`requested_reviewers` が空になるのは「レビュー完了」だけでなく「push で消化された」場合もある
- 再レビュー結果は `reviews` の末尾に追加される（`.[-1]` で最新を取得）

### レビュー見逃し防止チェック

Copilot のレビューは依頼から数分で届く。`sleep` だけで待つのではなく、**必ずレビュー件数をポーリングで確認してから次のステップに進むこと**。

#### 件数の記録と比較

```bash
# レビュー依頼前に現在の Copilot レビュー件数を記録しておく
BEFORE=$(gh api repos/takanogenichi/axolLoop/pulls/<PR番号>/reviews \
  --jq '[.[] | select(.user.login == "copilot-pull-request-reviewer[bot]")] | length')
```

#### 自動ポーリング（推奨）

レビュー依頼後、15 秒間隔で到着を自動チェックする。最大 5 分（20 回）でタイムアウト。
`<BEFORE件数>` にはレビュー依頼前に記録した件数を入れる。

```bash
for i in $(seq 1 20); do sleep 15; AFTER=$(gh api repos/takanogenichi/axolLoop/pulls/<PR番号>/reviews --jq '[.[] | select(.user.login == "copilot-pull-request-reviewer[bot]")] | length' 2>&1); echo "$(date +%H:%M:%S) check$i: count=$AFTER"; if [[ "$AFTER" -gt <BEFORE件数> ]]; then echo "ARRIVED"; break; fi; done
```

**ポイント**:
- 1 行で書くこと（zsh の複数行 for ループはターミナル環境によって途中で送信されてしまう場合がある）
- `2>&1` を付けてエラー出力も取り込む
- `ARRIVED` が表示されたら次のステップへ進む
- 20 回（5 分）経っても到着しない場合は GitHub 側の状態を手動確認する

### 正しいワークフロー順序（厳守）

**重要**: 修正の push と Copilot のレビュー完了がすれ違うと、レビュー結果を見落とす恐れがある。以下の順序を厳守すること。

```
レビュー依頼
  ↓
レビュー件数をチェック（到着するまで待つ）  ← 必ず確認
  ↓
コメント内容を読み、対応方針を決定
  ↓
修正・コミット・push
  ↓
不採用スレッドにコメント
  ↓
全スレッドを Resolve
  ↓
再レビュー依頼（→ 先頭に戻る）
```

**やってはいけないこと**:
- レビュー到着を確認せずに push や再レビュー依頼を行う
- `sleep` だけで待って確認せずに次ステップに進む
- push の前にレビューが届いていたのに無視して再レビューを投げる

**その他注意事項**
- このワークフローにしたがって、対象の Pull Request に対してのみ、ポーリングと、再レビュー依頼、レビュー件数チェック、コメント内容読み込み、全スレッド Resolve は、ユーザーにいちいち許可を求めなくても gh コマンドを実行してもよい
