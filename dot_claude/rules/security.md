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

#### Strict CSP（Content Security Policy）

CSP はインラインスクリプトや外部スクリプトの実行を制限し、XSS の影響を緩和する。
`nonce` または `hash` を使い、許可されたスクリプトのみ実行を認める。

```typescript
// Next.js の場合（middleware.ts）
import { NextResponse } from 'next/server';
import crypto from 'crypto';

export function middleware(request: Request) {
  const nonce = crypto.randomBytes(16).toString('base64');
  const csp = [
    `default-src 'self'`,
    `script-src 'self' 'nonce-${nonce}'`,  // nonce付きスクリプトのみ許可
    `style-src 'self' 'unsafe-inline'`,     // CSSは許可（Tailwind等）
    `img-src 'self' data: https:`,
    `connect-src 'self' https://api.example.com`,
    `frame-ancestors 'none'`,               // クリックジャッキング防止
  ].join('; ');

  const response = NextResponse.next();
  response.headers.set('Content-Security-Policy', csp);
  return response;
}
```

**❌ NEVER:**
```
script-src 'unsafe-inline' 'unsafe-eval'  // XSS対策が無効化される
```

#### CORS（Cross-Origin Resource Sharing）

**❌ NEVER（本番環境）:**
```typescript
// ワイルドカードは開発環境のみ
app.use(cors({ origin: '*' }));

// credentials と * の組み合わせは動作しない
app.use(cors({ origin: '*', credentials: true }));
```

**✅ ALWAYS:**
```typescript
// 明示的に信頼するオリジンを指定
const ALLOWED_ORIGINS = [
  'https://app.example.com',
  'https://admin.example.com',
];

app.use(cors({
  origin: (origin, callback) => {
    if (!origin || ALLOWED_ORIGINS.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
}));
```

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

## フロントエンド認証・認可

関連: @~/.claude/rules/web-frontend.md

### OIDC認証方式の比較

フロントエンドアプリケーションでOIDC（OpenID Connect）を使用する際の3つの方式：

| 方式 | トークン保存場所 | セキュリティ | 実装複雑度 | 適用場面 |
|------|----------------|-------------|-----------|---------|
| **BFF（Backend for Frontend）Cookie** | サーバー側（Cookie経由） | 最高 | 中 | **推奨**。本番サービス |
| **サーバー経由 JWT** | サーバーでトークン管理、フロントにJWT返却 | 高 | 高 | マイクロサービス間連携 |
| **フロント直接** | ブラウザ（メモリ / sessionStorage） | 中 | 低 | 社内ツール、PoC |

### 推奨: BFF パターン

```
ブラウザ → BFF（Cookie認証）→ IdP / APIサーバー
```

- トークンはサーバー側で管理、フロントには露出しない
- Cookie は `httpOnly` + `secure` + `sameSite`
- XSS でトークンが漏洩するリスクを排除

```typescript
// BFF 側: Cookie にセッションを設定
app.get('/auth/callback', async (req, res) => {
  const tokens = await exchangeCodeForTokens(req.query.code);
  // トークンはサーバー側のセッションストアに保存
  req.session.accessToken = tokens.accessToken;
  req.session.refreshToken = tokens.refreshToken;

  res.cookie('session_id', req.sessionID, {
    httpOnly: true,
    secure: true,
    sameSite: 'lax',
  });
  res.redirect('/');
});

// BFF 側: API プロキシ
app.get('/api/:path(*)', async (req, res) => {
  const token = req.session.accessToken;
  const response = await fetch(`${API_BASE}/${req.params.path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  res.json(await response.json());
});
```

### フロントエンド認可 = UXのみ

> フロントエンドの認可チェックは**UX目的**であり、セキュリティではない。
> セキュリティの担保は**バックエンド**が行う。

```typescript
// フロントエンド: UX として非表示にする（バイパス可能）
{user.role === 'admin' && <AdminPanel />}

// バックエンド: セキュリティとして検証する（バイパス不可）
app.get('/api/admin/users', requireRole('admin'), (req, res) => {
  // ...
});
```

**理由**:
- フロントエンドのコードはブラウザの DevTools で改変可能
- API リクエストは直接送信可能（UI をバイパス）
- フロントエンドの条件分岐を信頼してはならない

### トークン保存場所の選定基準

| 保存場所 | XSS耐性 | CSRF耐性 | 持続性 | 備考 |
|---------|---------|---------|--------|------|
| **httpOnly Cookie** | 高（JSからアクセス不可） | `sameSite` で対策 | セッション～永続 | **推奨** |
| **メモリ（変数）** | 高（DOMに露出しない） | 高 | リロードで消失 | SPA で BFF 使用時 |
| **sessionStorage** | 低（XSSで読取可能） | 高 | タブ内のみ | 非推奨 |
| **localStorage** | 低（XSSで読取可能） | 高 | 永続 | **非推奨** |

```typescript
// ❌ NEVER: localStorage にトークンを保存
localStorage.setItem('token', accessToken);

// ✅ BFF 使用時: Cookie で自動送信
fetch('/api/users', { credentials: 'include' });

// ✅ やむを得ずフロントで保持する場合: メモリのみ
// （リロード時は再認証 or サイレントリフレッシュ）
let accessToken: string | null = null;

function setToken(token: string) {
  accessToken = token;
}
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

---

## 参考資料

- [IPA 安全なウェブサイトの作り方](https://www.ipa.go.jp/security/vuln/websecurity.html)
- [Zenn catnose99 - Webサービス公開前のチェックリスト](https://zenn.dev/catnose99/articles/547cbf57e5ad28)
