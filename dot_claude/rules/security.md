# セキュリティルール

コミット前に確認すべきセキュリティ項目。

---

## 必須チェックリスト

コードを書く際、以下を常に確認する：

### 1. 秘密情報の管理

**❌ NEVER:**
```typescript
// ハードコードされた秘密情報
const API_KEY = "sk-1234567890abcdef";
const PASSWORD = "admin123";
```

**✅ ALWAYS:**
```typescript
// 環境変数から取得
const API_KEY = process.env.API_KEY;
if (!API_KEY) {
  throw new Error("API_KEY is not set");
}
```

### 2. 入力検証

すべてのユーザー入力を検証する：

```typescript
// ❌ BAD
function processInput(data: any) {
  return database.query(data.id);
}

// ✅ GOOD
function processInput(data: unknown) {
  const parsed = schema.parse(data); // zodなどで検証
  return database.query(parsed.id);
}
```

### 3. SQLインジェクション対策

**❌ NEVER:**
```typescript
// 文字列連結でクエリを構築
const query = `SELECT * FROM users WHERE id = '${userId}'`;
```

**✅ ALWAYS:**
```typescript
// パラメータ化クエリを使用
const query = `SELECT * FROM users WHERE id = $1`;
await db.query(query, [userId]);
```

### 4. XSS対策

**❌ NEVER:**
```typescript
// dangerouslySetInnerHTML を無検証で使用
<div dangerouslySetInnerHTML={{ __html: userInput }} />
```

**✅ ALWAYS:**
```typescript
// サニタイズする
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userInput) }} />

// または、テキストとして扱う
<div>{userInput}</div>
```

### 5. 認証・認可

- すべての保護されたエンドポイントで認証を確認
- ユーザーの権限を検証してからデータを返す
- セッションの有効期限を適切に設定

### 6. エラーハンドリング

**❌ NEVER:**
```typescript
// スタックトレースをユーザーに露出
catch (error) {
  res.status(500).json({ error: error.stack });
}
```

**✅ ALWAYS:**
```typescript
// 一般的なエラーメッセージを返す
catch (error) {
  console.error(error); // ログには詳細を記録
  res.status(500).json({ error: "Internal server error" });
}
```

### 7. レート制限

すべての公開エンドポイントにレート制限を適用：

```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分
  max: 100, // 最大100リクエスト
});

app.use('/api/', limiter);
```

### 8. HTTPS

本番環境では常にHTTPSを使用。HTTPへのリダイレクトを設定。

### 9. Cookie属性

認証Cookieには以下の属性を必ず設定：

```typescript
res.cookie('session', token, {
  httpOnly: true,    // JavaScriptからアクセス不可（XSS対策）
  secure: true,      // HTTPS接続時のみ送信
  sameSite: 'lax',   // CSRF対策（'strict'はUX影響あり）
  // domain: 不必要に設定しない（サブドメイン間の脆弱性波及を防ぐ）
});
```

### 10. セキュリティヘッダ

レスポンスヘッダで追加の保護を設定：

```typescript
// helmet等を使用
app.use(helmet({
  contentSecurityPolicy: true,
  xssFilter: true,
  noSniff: true,
  frameguard: { action: 'deny' },
}));
```

主要なヘッダ：
- `X-Content-Type-Options: nosniff` - MIMEタイプスニッフィング防止
- `X-Frame-Options: DENY` - クリックジャッキング防止
- `Content-Security-Policy` - インラインスクリプト制限

### 11. ユーザー名のリザーブド文字列

ユーザーが選択できるハンドルネームから除外すべき文字列：

```typescript
const RESERVED_USERNAMES = [
  'admin', 'administrator', 'root', 'system',
  'api', 'www', 'mail', 'ftp', 'support',
  'help', 'info', 'security', 'abuse',
  'null', 'undefined', 'true', 'false',
];
```

---

## 問題発見時のフロー

セキュリティ問題を検出した場合：

```
1. 即座に作業を中断
    ↓
2. 問題の重大度を評価
    ↓
3. Critical な場合:
   - 漏洩した秘密情報をローテーション
   - 影響範囲を特定
    ↓
4. 修正を実装
    ↓
5. 類似問題がないか全体をレビュー
    ↓
6. 再発防止策を検討
```

---

## 重大度分類

| 重大度 | 例 | 対応 |
|--------|-----|------|
| **Critical** | 秘密情報の漏洩、認証バイパス | 即座に修正、デプロイ停止 |
| **High** | SQLインジェクション、XSS | 次のリリース前に修正 |
| **Medium** | 不適切なエラーメッセージ | 計画的に修正 |
| **Low** | ベストプラクティス違反 | 時間があれば修正 |

---

## 自動チェックコマンド

```bash
# 秘密情報の検出
grep -rn --include="*.ts" --include="*.js" \
  -E "(api[_-]?key|secret|password|token).*=.*['\"][^'\"]{8,}['\"]" .

# .env がコミットされていないか
git ls-files | grep -E "\.env$"

# デバッグコードの検出
grep -rn --include="*.ts" --include="*.js" \
  -E "(console\.(log|debug)|debugger)" src/
```
