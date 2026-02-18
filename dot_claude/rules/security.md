# セキュリティルール

コミット前に確認すべきセキュリティ項目。

---

## 必須チェックリスト

コードを書く際、以下を常に確認する：

### 1. 秘密情報の管理

**❌ NEVER:**
```typescript
// ハードコードされた秘密情報
const API_KEY = "YOUR_API_KEY_HERE";
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

XSS は発生メカニズムにより3種類に分類される：

| 種類 | 仕組み | 特徴 |
|------|--------|------|
| **Reflected（反射型）** | URLパラメータ等の攻撃コードをサーバがそのままHTMLに返却 | 罠リンクのクリックが必要。非持続型 |
| **Stored（蓄積型）** | 投稿フォーム等から送信された不正スクリプトがDBに保存され、閲覧者のブラウザで実行 | 不特定多数に影響。最も危険 |
| **DOM-based** | クライアントサイドのJSがDOMを操作する際に発生。サーバを経由しない | `innerHTML` や `javascript:` スキームが原因 |

#### 基本対策：エスケープ

React/Vue 等のモダンフレームワークはデフォルトで変数をエスケープする。以下は生のHTML操作が必要な場合の対策。

**❌ NEVER:** `dangerouslySetInnerHTML` を無検証で使用

**✅ ALWAYS:**
```typescript
// サニタイズする
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userInput) }} />

// または、テキストとして扱う
<div>{userInput}</div>
```

#### DOM-based XSS 対策

```typescript
// ❌ BAD: innerHTML はスクリプトを実行する可能性がある
element.innerHTML = userInput;

// ✅ GOOD: textContent は常にテキストとして扱う
element.textContent = userInput;
```

```typescript
// ❌ BAD: javascript: スキームによる実行
<a href={userInput}>リンク</a>

// ✅ GOOD: スキームを http/https に限定
const isSafeUrl = (url: string) =>
  /^https?:\/\//i.test(url) || url.startsWith('/');
{isSafeUrl(userInput) && <a href={userInput}>リンク</a>}
```

### 5. 認証・認可

- すべての保護されたエンドポイントで認証を確認
- ユーザーの権限を検証してからデータを返す
- セッションの有効期限を適切に設定
- Bearer token 検証では `replace` ではなく `match` を使い、スキームの存在を必須にする

```typescript
// ❌ BAD: Bearer プレフィックスなしの token がそのまま通過する
const token = authHeader.replace(/^Bearer\s+/i, "");
if (token !== expectedToken) { /* reject */ }

// ✅ GOOD: Bearer スキームが必須。プレフィックスなしは拒否される
const match = authHeader.match(/^Bearer\s+(.+)$/i);
if (!match || match[1] !== expectedToken) { /* reject */ }
```

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

#### HTTPS（TLS）で暗号化される範囲

TLS ハンドシェイク後、**HTTP リクエスト全体**が暗号化される。

| 暗号化される（外部から見えない） | 暗号化されない（外部から見える） |
|-------------------------------|-------------------------------|
| リクエストパス（`/api/users`） | 接続先 IP アドレス |
| ヘッダー（`Authorization: Bearer ...`） | SNI（ホスト名、例: `api.example.com`） |
| クエリパラメータ（`?key=value`） | 通信量・タイミング |
| リクエストボディ | |
| レスポンス全体 | |

Bearer Token を HTTPS のヘッダーで送信するのは安全。通信経路上での傍受はできない。

#### クエリパラメータに秘密情報を含めてはいけない理由

HTTPS で暗号化されるにもかかわらず、クエリパラメータは以下の経路で漏洩する：

- **ブラウザ履歴**: `?token=xxx` が履歴に残る
- **サーバーアクセスログ**: リクエスト URL がログに記録される
- **Referer ヘッダー**: 外部リンクをクリックすると遷移先に URL が送信される
- **プロキシ/CDN ログ**: TLS 終端後のログに URL が記録される可能性

```
❌ BAD: https://app.example.com/dashboard?token=secret123
✅ GOOD: Authorization: Bearer secret123（ヘッダーで送信）
```

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

#### SameSite の判定基準と注意点

SameSite は eTLD+1（registrable domain）が同じかどうかで判定する。Same origin（スキーム＋ホスト＋ポートの完全一致）とは異なるゆるい基準。

```
app.example.com と api.example.com → Same site（eTLD+1 = example.com）
your-app.github.io と my-app.github.io → Cross-site（eTLD = github.io）
```

サブドメイン間は Same site 扱いのため、**脆弱なサブドメインがあると SameSite による保護が効かない**。`domain` 属性を不必要に設定しない理由もここにある。

| 値 | Cookie送信条件 | 用途 |
|---|---|---|
| **Lax**（デフォルト） | 同一サイト + 外部からのトップレベルGETナビゲーション | 一般的な認証Cookie |
| **Strict** | 同一サイトのみ（外部リンク遷移でも送らない） | 高セキュリティ操作 |
| **None** | どこからでも送信（`Secure` 必須） | Cross-site 埋め込みが必要な場合のみ |

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
- `Strict-Transport-Security: max-age=31536000; includeSubDomains` - HTTPS強制（HSTS）
- `X-Content-Type-Options: nosniff` - MIMEタイプスニッフィング防止
- `X-Frame-Options: DENY` - クリックジャッキング防止
- `Content-Security-Policy` - リソース読み込み制限（XSS緩和）
- `Permissions-Policy` - ブラウザ機能（カメラ・マイク等）の制限
- `Cache-Control: no-store` - 機密ページのキャッシュ防止
- `Cross-Origin-Opener-Policy: same-origin` - 他オリジンとの `window.opener` 関係を遮断

#### HSTS（HTTP Strict Transport Security）

ブラウザに HTTPS 通信を強制し、SSLストリッピング（HTTPSをHTTPにダウングレードする中間者攻撃）を防ぐ。

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

- `max-age`: HTTPS を強制する期間（秒）。31536000 = 1年
- `includeSubDomains`: サブドメインにも適用
- **注意**: HTTP でアクセスした場合にブラウザが自動で HTTPS に変換する。初回アクセス前の保護には HSTS Preload List への登録が必要

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
    `script-src 'nonce-${nonce}' 'strict-dynamic'`, // Strict CSP: nonce + 動的スクリプト許可
    `style-src 'self' 'unsafe-inline'`,              // CSSは許可（Tailwind等）
    `img-src 'self' data: https:`,
    `connect-src 'self' https://api.example.com`,
    `object-src 'none'`,                             // Flash等プラグイン禁止
    `base-uri 'self'`,                               // <base>タグによるURLハイジャック防止
    `frame-ancestors 'none'`,                        // クリックジャッキング防止
  ].join('; ');

  const response = NextResponse.next();
  response.headers.set('Content-Security-Policy', csp);
  return response;
}
```

**Strict CSP の要点**:
- `nonce-{RANDOM}`: リクエストごとにランダムな nonce を生成し、許可するスクリプトに付与
- `strict-dynamic`: nonce で許可されたスクリプトから動的に読み込まれるスクリプトも自動許可（GA等の外部スクリプト対応）
- `object-src 'none'`: プラグイン経由の攻撃を防止
- `base-uri 'self'`: `<base>` タグによる URL ハイジャックを防止

**❌ NEVER:**
```
script-src 'unsafe-inline' 'unsafe-eval'  // XSS対策が無効化される
```

#### CSP Report-Only モード

本番導入前にテストする場合、`Content-Security-Policy-Report-Only` ヘッダーを使用する。
実際のブロックは行わず、違反レポートのみ送信される。

```
Content-Security-Policy-Report-Only: script-src 'nonce-xxx' 'strict-dynamic'; report-uri /csp-report
```

#### Trusted Types（DOM XSS 根本対策）

`innerHTML` 等の危険なシンクに文字列を直接代入することを禁止し、ポリシーで検査された「安全な型」のみ許可する仕組み。Strict CSP と併用することで強力な防御になる。

```
Content-Security-Policy: trusted-types default; require-trusted-types-for 'script'
```

#### COOP（Cross-Origin-Opener-Policy）

他オリジンとの `window.opener` 関係をプロセスレベルで遮断し、Tabnabbing や Spectre 系サイドチャネル攻撃を防ぐ。`rel="noopener"` がリンク側の対策であるのに対し、COOP は**リンクされる側（自サイト）が設定する**防御。

```
Cross-Origin-Opener-Policy: same-origin
```

| 値 | 挙動 |
|---|---|
| `unsafe-none`（デフォルト） | 制限なし。他オリジンから `window.opener` でアクセス可能 |
| `same-origin` | 同一オリジンのみ browsing context group を共有 |
| `same-origin-allow-popups` | 自分が開いた popup との関係は維持 |

**OAuth ポップアップとの互換性**:

`same-origin` を設定すると、Cross-origin の popup との `postMessage` 通信が切断される。OAuth のポップアップログインフロー（Google Sign-In 等）を使用している場合は `same-origin-allow-popups` を選択する。

```typescript
// OAuth ポップアップフローがない場合（推奨）
response.headers.set('Cross-Origin-Opener-Policy', 'same-origin');

// OAuth ポップアップフローがある場合
response.headers.set('Cross-Origin-Opener-Policy', 'same-origin-allow-popups');
```

#### CORS（Cross-Origin Resource Sharing）

**重要**: CORS は「ブラウザがレスポンスを読み取ることを許可する」仕組みであり、サーバへのリクエスト送信自体を止めるものではない。CSRF 対策にはならない。

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

### 11. リンクのセキュリティ（Tabnabbing 対策）

`target="_blank"` で開いた別タブは `window.opener` を通じて元タブを操作できる（フィッシングサイトへの書き換え等）。

**✅ ALWAYS:**
```html
<a href="https://external.example.com" target="_blank" rel="noopener noreferrer">
  外部リンク
</a>
```

- `noopener`: `window.opener` を `null` にし、元タブへのアクセスを防止
- `noreferrer`: Referer ヘッダーの送信も防止
- **注意**: 最新ブラウザではデフォルトで `noopener` 相当の挙動だが、明示することを推奨

### 12. サブリソース完全性（SRI）

CDN 等の外部サーバからスクリプトを読み込む際、ファイルが改ざんされていないかを検証する。

```html
<script
  src="https://cdn.example.com/lib.js"
  integrity="sha384-xxxxx"
  crossorigin="anonymous"
></script>
```

- ハッシュが一致しない場合、ブラウザはスクリプトの実行をブロック
- CDN の侵害やサプライチェーン攻撃への緩和策

### 13. ユーザー名のリザーブド文字列

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

**原因**: リクエストの出自が検証されない（攻撃者サイトから被害者のブラウザ経由で Cookie 付きリクエストが送信される）

**現代のベースプラクティス**（Jxck氏）:
1. 副作用のある API を GET にしない（POST 使用）
2. `Origin` ヘッダ確認（ブラウザが強制付与、JS から偽装不可）
3. `SameSite=Lax` 以上を明示（Cross-site の POST で Cookie が送られない）
4. Fetch Metadata（`Sec-Fetch-Site` ヘッダ）確認

これらがトークン導入以前の前提。CSRF トークンはこの上に追加する多層防御として位置づける。

**追加対策**:
- CSRF トークンを hidden パラメータに埋め込み検証
- 重要操作時にパスワード再認証

### HTTPヘッダインジェクション

**原因**: HTTPレスポンスヘッダに外部入力を含める際の改行コード処理不備

**対策**:
- ヘッダ出力用APIを使用
- 外部入力から改行コードを削除

### クリックジャッキング

**原因**: 透明なiframeを重ねて意図しないクリックを誘導

**現状**: SameSite=Lax がデフォルトの現代では、Cross-site の iframe 内に Cookie が送られないため認証済み操作を狙った攻撃は成立しにくい。ただしサブドメイン間は Same site 扱い（eTLD+1 が同じ）のため、脆弱なサブドメインからの攻撃は依然成立しうる。

**対策**:
- `X-Frame-Options: DENY`または`SAMEORIGIN`（多層防御として引き続き必須）
- `Content-Security-Policy: frame-ancestors 'none'`（CSP版、推奨）
- 重要操作時にパスワード再認証

### アクセス制御・認可制御の欠落

**原因**: URLやパラメータのユーザーIDをセッションと照合しない

**対策**:
- ユーザーIDはセッション変数から取得
- リソースアクセス時に権限を常に検証

### オープンリダイレクト

**原因**: `?next=http://evil.com` のようなパラメータでリダイレクト先を外部から指定可能

**攻撃手法**: 信頼されたサイトのログインURLに罠パラメータを付与し、ログイン後にフィッシングサイトへ誘導

**対策**:
- リダイレクト先を許可ドメインのホワイトリストで検証
- 外部ドメインへの遷移が不要なら `/` で始まる相対パスのみ受け付ける
- **注意**: `//evil.com` のようなプロトコル相対URLでバイパスされないよう、先頭が `//` でないことも検証する

---

## サプライチェーン攻撃

フロントエンド開発は多数の npm パッケージに依存するため、その依存関係を狙った攻撃が脅威となる。

### 攻撃手法

- **タイポスクワッティング**: `react` に対して `raect` のような紛らわしい名前の悪意あるパッケージ
- **依存パッケージの乗っ取り**: メンテナのアカウントが侵害され、悪意あるコードが混入

### 対策

- `npm audit` / `pnpm audit` を CI/CD パイプラインに組み込み、既知の脆弱性を自動スキャン
- lockfile（`pnpm-lock.yaml` 等）を必ずバージョン管理に含め、同一バージョンを保証
- SRI（サブリソース完全性）を CDN から読み込むスクリプトに設定
- 依存パッケージの更新は差分を確認してからマージ

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
