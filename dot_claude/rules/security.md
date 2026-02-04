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

## Webアプリケーション脆弱性対策（IPA準拠）

### OSコマンドインジェクション

**原因**: シェルを起動する関数（Perlの`open()`等）に外部入力を渡す

**対策**:
- シェルを起動しない関数を使用（`sysopen()`等）
- やむを得ない場合はホワイトリスト検証

### ディレクトリトラバーサル

**原因**: ファイル名をパラメータで直接指定する実装

**対策**:
- ファイル名を直接指定しない設計
- `basename()`でディレクトリ名を除去
- `../`等のパス指定文字を検出・拒否

### セッション管理の不備

**原因**: セッションIDの生成・管理が不適切

**対策**:
- 暗号論的擬似乱数でセッションID生成
- URLではなくCookieに格納（`secure`属性付き）
- ログイン成功時に新しいセッションを発行

### CSRF（クロスサイト・リクエスト・フォージェリ）

**原因**: リクエストが利用者の意図かどうかを検証しない

**対策**:
- CSRFトークンをhiddenパラメータに埋め込み検証
- 重要操作時にパスワード再認証
- `SameSite`属性付きCookie

### HTTPヘッダインジェクション

**原因**: HTTPレスポンスヘッダに外部入力を含める際の改行コード処理不備

**対策**:
- ヘッダ出力用APIを使用
- 外部入力から改行コードを削除

### クリックジャッキング

**原因**: 透明なiframeを重ねて意図しないクリックを誘導

**対策**:
- `X-Frame-Options: DENY`または`SAMEORIGIN`
- 重要操作時にパスワード再認証

### アクセス制御・認可制御の欠落

**原因**: URLやパラメータのユーザーIDをセッションと照合しない

**対策**:
- ユーザーIDはセッション変数から取得
- リソースアクセス時に権限を常に検証

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

---

## 参考資料

- [IPA 安全なウェブサイトの作り方](https://www.ipa.go.jp/security/vuln/websecurity.html)
- [Zenn catnose99 - Webサービス公開前のチェックリスト](https://zenn.dev/catnose99/articles/547cbf57e5ad28)
