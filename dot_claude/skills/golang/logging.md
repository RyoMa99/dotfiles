## 構造化ログ設計（slog）

Go 1.21+ の標準ライブラリ `log/slog` を使った構造化ログのベストプラクティス。

関連: `error-handling.md`（Split-Brain Error Types — ログ出力とユーザー向けメッセージの分離）
関連: `/log-design` スキル（言語横断のログ設計原則）

---

## slog の基本構成

### ハンドラの選択

```go
// 開発環境: テキスト形式（人間が読みやすい）
handler := slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{
    Level: slog.LevelDebug,
})

// 本番環境: JSON 形式（構造化ログ基盤に送信）
handler := slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{
    Level: slog.LevelInfo,
})

slog.SetDefault(slog.New(handler))
```

### Context 付きログ

HTTP リクエストのトレース ID やユーザー ID をログに含めるために、常に `Context` 付きのメソッドを使う。

```go
// GOOD: Context 経由でリクエスト固有の情報を伝播
slog.InfoContext(ctx, "order processed",
    "order_id", order.ID,
    "amount", order.Total,
)

// ミドルウェアで Context にロガーを仕込む
func RequestLogger(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        logger := slog.Default().With(
            "request_id", r.Header.Get("X-Request-ID"),
            "method", r.Method,
            "path", r.URL.Path,
        )
        ctx := context.WithValue(r.Context(), loggerKey, logger)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

---

## LogValuer による秘匿フィールドの制御

`slog.LogValuer` インターフェースを実装すると、構造体がログに出力される際の内容を制御できる。サードパーティライブラリ不要で、標準ライブラリだけで秘匿情報を保護できる。

### 基本パターン: allow-list 方式

ログに出してよいフィールドだけを明示的に選択する。新しいフィールドが追加されても、allow-list に追加しない限りログに出ない。

```go
type User struct {
    ID       string
    Name     string
    Email    string
    Password string // ログに出したくない
    APIToken string // ログに出したくない
}

// LogValuer: ログに出すフィールドを明示的に選択（allow-list）
func (u User) LogValue() slog.Value {
    return slog.GroupValue(
        slog.String("id", u.ID),
        slog.String("name", u.Name),
        slog.String("email", u.Email),
        // Password, APIToken は意図的に省略
    )
}
```

```go
// 使用例
slog.Info("user created", "user", user)
// 出力: level=INFO msg="user created" user.id=abc123 user.name=Alice user.email=alice@example.com
// Password と APIToken は含まれない
```

### 秘匿型の定義

パスワードやトークンなど、決してログに出してはいけない値を型で保護する。

```go
// Secret: ログ出力時に自動的にマスクされる型
type Secret string

func (s Secret) LogValue() slog.Value {
    return slog.StringValue("[REDACTED]")
}

func (s Secret) String() string {
    return "[REDACTED]"
}

// 使用例
type Config struct {
    Host     string
    Port     int
    Password Secret // fmt.Println でも slog でもマスクされる
}
```

`robust-code.md` の「プリミティブ型を避ける」原則と同じ。`string` の代わりに `Secret` 型を使うことで、うっかりログに出力してもマスクされる。

---

## Canonical Log Lines

リクエスト処理の完了時に、そのリクエストに関する全情報を**1行のログ**にまとめるパターン。Stripe が提唱。

### なぜ必要か

散在する複数のログ行から情報を集めるのは困難。Canonical Log Line は1行に集約されているため、検索・集計・アラートが容易。

```go
// BAD: 情報が複数行に散在
slog.Info("received request", "path", "/api/orders")
slog.Info("authenticated user", "user_id", "abc123")
slog.Info("queried database", "duration_ms", 45)
slog.Info("sent response", "status", 200)

// GOOD: Canonical Log Line（1リクエスト = 1行に集約）
slog.Info("request completed",
    "request_id", requestID,
    "method", "POST",
    "path", "/api/orders",
    "status", 200,
    "user_id", "abc123",
    "duration_ms", 150,
    "db_queries", 3,
    "db_duration_ms", 45,
)
```

### 実装パターン: ミドルウェアで集約

```go
// RequestMetrics: リクエスト処理中に情報を蓄積
type RequestMetrics struct {
    mu          sync.Mutex
    attrs       []slog.Attr
}

func (m *RequestMetrics) Add(key string, value any) {
    m.mu.Lock()
    defer m.mu.Unlock()
    m.attrs = append(m.attrs, slog.Any(key, value))
}

// ミドルウェア: リクエスト完了時に Canonical Log Line を出力
func CanonicalLogMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        metrics := &RequestMetrics{}
        ctx := context.WithValue(r.Context(), metricsKey, metrics)

        // レスポンスのステータスコードを記録するラッパー
        rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
        next.ServeHTTP(rw, r.WithContext(ctx))

        // Canonical Log Line: リクエスト完了時に1行で出力
        attrs := []any{
            "request_id", r.Header.Get("X-Request-ID"),
            "method", r.Method,
            "path", r.URL.Path,
            "status", rw.statusCode,
            "duration_ms", time.Since(start).Milliseconds(),
        }
        for _, a := range metrics.attrs {
            attrs = append(attrs, a.Key, a.Value.Any())
        }
        slog.InfoContext(ctx, "request completed", attrs...)
    })
}

// 各ハンドラ/サービスから情報を追加
func (h *OrderHandler) CreateOrder(w http.ResponseWriter, r *http.Request) {
    metrics := r.Context().Value(metricsKey).(*RequestMetrics)
    metrics.Add("user_id", userID)
    metrics.Add("order_id", order.ID)
    // ...
}
```

---

## ログレベルの判断フロー

```
何が起きた？
    ├─ 処理が失敗した
    │   ├─ リトライ可能 or 想定内 → Warn
    │   └─ リトライ不可 or 想定外 → Error
    │
    ├─ 正常に処理された
    │   ├─ 業務イベント（ユーザー操作、状態変更） → Info
    │   └─ 技術的な内部動作 → Debug
    │
    └─ 開発/デバッグ用の詳細情報 → Debug
```

### Error ログの注意点

```go
// BAD: 同じエラーを複数箇所でログ出力（ログ爆発）
func (r *Repo) FindByID(ctx context.Context, id string) (*User, error) {
    user, err := r.db.QueryRowContext(ctx, "SELECT ...", id)
    if err != nil {
        slog.Error("query failed", "err", err) // ← ここでログ
        return nil, fmt.Errorf("query user: %w", err)
    }
    return user, nil
}
func (u *UseCase) GetUser(ctx context.Context, id string) (*User, error) {
    user, err := u.repo.FindByID(ctx, id)
    if err != nil {
        slog.Error("get user failed", "err", err) // ← ここでもログ（重複！）
        return nil, err
    }
    return user, nil
}

// GOOD: エラーは上位（ハンドラ / Canonical Log Line）で1回だけログ出力
// 下位層はエラーをラップして返すだけ
func (r *Repo) FindByID(ctx context.Context, id string) (*User, error) {
    user, err := r.db.QueryRowContext(ctx, "SELECT ...", id)
    if err != nil {
        return nil, fmt.Errorf("query user %s: %w", id, err) // ラップのみ
    }
    return user, nil
}
```

**原則: エラーはラップして上に返す。ログ出力は境界（ハンドラ）で1回だけ。**

---

## slog のカスタムハンドラ

特殊な要件がある場合、`slog.Handler` インターフェースを実装してカスタムハンドラを作成できる。

### よくあるカスタマイズ

| 要件 | 実装方法 |
|------|---------|
| 秘匿フィールドの自動除去 | `Handle()` で属性をフィルタリング |
| トレース ID の自動付与 | `Handle()` で Context からトレース ID を取得して追加 |
| ログレベルの動的変更 | `LevelVar` を使用（ランタイムで変更可能） |
| 複数出力先 | ファンアウトハンドラ（stdout + ファイル） |

```go
// LevelVar: ランタイムでログレベルを動的に変更
var logLevel = new(slog.LevelVar)
logLevel.Set(slog.LevelInfo) // デフォルト

handler := slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{
    Level: logLevel,
})

// API エンドポイントでレベル変更（デバッグ時に一時的に Debug に）
func handleSetLogLevel(w http.ResponseWriter, r *http.Request) {
    level := r.URL.Query().Get("level")
    switch level {
    case "debug":
        logLevel.Set(slog.LevelDebug)
    case "info":
        logLevel.Set(slog.LevelInfo)
    }
}
```

---

## 構造化ログのアンチパターン

### 1. 文字列結合でメッセージを組み立てる

```go
// BAD: 構造化の恩恵がない
slog.Info(fmt.Sprintf("user %s created order %s", userID, orderID))

// GOOD: 検索・フィルタ可能な構造化フィールド
slog.Info("order created", "user_id", userID, "order_id", orderID)
```

### 2. 構造体をそのまま出力

```go
// BAD: Password 等が含まれる可能性
slog.Info("user", "data", user) // LogValuer 未実装なら全フィールドが出る

// GOOD: LogValuer を実装するか、必要なフィールドだけ出力
slog.Info("user", "user", user) // LogValuer 実装済み
slog.Info("user", "id", user.ID, "name", user.Name) // 明示的に選択
```

### 3. ログメッセージに変数を含める

```go
// BAD: メッセージが毎回異なり、集計できない
slog.Info("processed order abc123")
slog.Info("processed order def456")

// GOOD: メッセージは固定、変数はフィールドに
slog.Info("order processed", "order_id", "abc123")
slog.Info("order processed", "order_id", "def456")
// → "order processed" で grep すると全注文処理が引っかかる
```

---

## 参考資料

- [Go Blog - Structured Logging with slog](https://go.dev/blog/slog)
- [pkg.go.dev - log/slog](https://pkg.go.dev/log/slog)
- [Stripe - Canonical Log Lines](https://stripe.com/blog/canonical-log-lines-2)
- [Peter Bourgon - Logging v. Instrumentation](https://peter.bourgon.org/blog/2016/02/07/logging-v-instrumentation.html)
