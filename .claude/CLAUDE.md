# プロジェクト コーディングガイドライン

## N+1 クエリの禁止

ループ（`for`, `forEach`, `map`, `while` など）の内部でデータベースクエリや外部 API への取得リクエストを実行してはならない。

### 理由

- ループの反復回数に比例してクエリ数が増加し、パフォーマンスが著しく劣化する（N+1 問題）
- データベースやネットワークへの負荷が不必要に高くなる

### 対処方法

- ループの**前**に必要なデータを一括取得（バッチ取得）し、ループ内ではメモリ上のデータを参照する
- Prisma の場合: `findMany` + `where: { id: { in: ids } }` などでまとめて取得する
- リレーション取得の場合: `include` や `select` でリレーションを事前にロードする
- どうしてもループ内で個別取得が必要な場合は、その理由をコメントに明記すること

### 悪い例

```typescript
// NG: ループ内でクエリを実行している
for (const userId of userIds) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  results.push(user);
}
```

### 良い例

```typescript
// OK: ループの前に一括取得
const users = await prisma.user.findMany({
  where: { id: { in: userIds } },
});
```
