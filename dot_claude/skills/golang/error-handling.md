## セキュアなエラーハンドリング

Go の「エラーは値」パラダイムにおけるセキュリティリスクと対策パターン。

関連: `robust-code.md`（Parse, don't Validate — エラー型も「パース済み」の概念が適用できる）
関連: `layered-architecture.md`（変換は両端の2箇所に閉じ込める — エラー変換も同様）

---

## 境界を跨ぐエラーの翻訳

`layered-architecture.md` の「変換は両端に閉じ込める」原則をエラーにも適用する。内部のエラーをそのまま外部に返さず、境界ごとに翻訳する。

```
ドメイン層        → ドメインエラー（ErrInsufficientStock 等）
    ↓
アプリケーション層 → そのまま伝播（翻訳不要）
    ↓
プレゼンテーション層 → HTTP/gRPC エラーに翻訳（ユーザー向けメッセージ）
    ↓
データソース層     → ドメインエラーに翻訳（sql.ErrNoRows → ErrNotFound）
```

```go
// データソース層: DB エラーをドメインエラーに翻訳
func (r *UserRepo) FindByID(ctx context.Context, id UserID) (*User, error) {
    row := r.db.QueryRowContext(ctx, "SELECT ...", id)
    var u User
    if err := row.Scan(&u.ID, &u.Name); err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrUserNotFound // ドメインエラーに翻訳
        }
        return nil, fmt.Errorf("query user %s: %w", id, err)
    }
    return &u, nil
}

// プレゼンテーション層: ドメインエラーを HTTP レスポンスに翻訳
func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
    user, err := h.usecase.GetUser(r.Context(), userID)
    if err != nil {
        switch {
        case errors.Is(err, ErrUserNotFound):
            http.Error(w, "ユーザーが見つかりません", http.StatusNotFound)
        default:
            slog.ErrorContext(r.Context(), "get user failed", "err", err) // 内部詳細はログへ
            http.Error(w, "内部エラーが発生しました", http.StatusInternalServerError)
        }
        return
    }
    // ...
}
```

---

## Split-Brain Error Types

内部用（ログ・デバッグ）とユーザー向け（レスポンス）のメッセージを構造体レベルで分離する。

```go
// AppError: 内部エラーとユーザー向けメッセージを型で分離
type AppError struct {
    // Internal: デバッグ用の詳細（ログに出力、ユーザーには見せない）
    Internal error
    // UserMsg: ユーザーに返す安全なメッセージ
    UserMsg string
    // Code: HTTP ステータスコードや gRPC コード
    Code int
}

func (e *AppError) Error() string { return e.UserMsg }
func (e *AppError) Unwrap() error { return e.Internal }

// コンストラクタで生成を強制
func NewAppError(internal error, userMsg string, code int) *AppError {
    return &AppError{Internal: internal, UserMsg: userMsg, Code: code}
}

func NewNotFoundError(internal error) *AppError {
    return NewAppError(internal, "リソースが見つかりません", http.StatusNotFound)
}

func NewInternalError(internal error) *AppError {
    return NewAppError(internal, "内部エラーが発生しました", http.StatusInternalServerError)
}
```

### HTTP ハンドラでの統一的なエラー処理

`func(w, r) error` パターンでハンドラのエラー処理を統一する。

```go
// AppHandler: error を返せるハンドラ型
type AppHandler func(w http.ResponseWriter, r *http.Request) error

// ServeHTTP: エラーを統一的に処理
func (fn AppHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    if err := fn(w, r); err != nil {
        var appErr *AppError
        if errors.As(err, &appErr) {
            slog.ErrorContext(r.Context(), "request failed",
                "err", appErr.Internal, // 内部詳細はログへ
                "code", appErr.Code,
                "path", r.URL.Path,
            )
            http.Error(w, appErr.UserMsg, appErr.Code) // ユーザーには安全なメッセージ
        } else {
            slog.ErrorContext(r.Context(), "unexpected error", "err", err)
            http.Error(w, "内部エラーが発生しました", http.StatusInternalServerError)
        }
    }
}

// 使用例: ハンドラは error を返すだけでよい
func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) error {
    user, err := h.usecase.GetUser(r.Context(), userID)
    if err != nil {
        if errors.Is(err, ErrUserNotFound) {
            return NewNotFoundError(fmt.Errorf("user %s: %w", userID, err))
        }
        return NewInternalError(fmt.Errorf("get user %s: %w", userID, err))
    }
    return json.NewEncoder(w).Encode(user)
}
```

---

## Opaque Wrapping

カスタムエラー型で `Unwrap()` を実装しないことで、内部のエラーチェーンを外部に漏らさない。

```go
// 境界を跨ぐエラー: Unwrap を実装しない
type DomainError struct {
    Message string
    cause   error // unexported: 外部から Unwrap できない
}

func (e *DomainError) Error() string { return e.Message }

// 内部でのみ原因を参照できるヘルパー
func (e *DomainError) LogValue() slog.Value {
    return slog.GroupValue(
        slog.String("message", e.Message),
        slog.Any("cause", e.cause),
    )
}
```

### いつ Unwrap を実装するか

```
エラーの利用者は誰か？
    ├─ 同一パッケージ内 / internal → Unwrap を実装してよい
    │   errors.Is / errors.As で種類を判別できる
    │
    └─ パッケージ外部 / 公開 API → Unwrap を実装しない
        内部実装の詳細（使用ライブラリ等）を隠蔽する
        代わりに Sentinel Error や型で判別手段を提供する
```

---

## Sentinel Error の設計

```go
// パッケージレベルで定義
var (
    ErrNotFound        = errors.New("not found")
    ErrAlreadyExists   = errors.New("already exists")
    ErrInvalidArgument = errors.New("invalid argument")
)

// ラップしても errors.Is で判定可能
func (r *Repo) FindByID(ctx context.Context, id string) (*Entity, error) {
    // ...
    if notFound {
        return nil, fmt.Errorf("entity %s: %w", id, ErrNotFound)
    }
    return &entity, nil
}

// 呼び出し側
if errors.Is(err, ErrNotFound) {
    // 404 を返す
}
```

---

## エラーハンドリングのアンチパターン

### 1. エラーの握り潰し

```go
// BAD: エラーを無視
result, _ := doSomething()

// GOOD: 明示的に処理するか、コメントで理由を記述
result, err := doSomething()
if err != nil {
    return fmt.Errorf("do something: %w", err)
}
```

### 2. 過剰なラップ（二重ラップ）

```go
// BAD: 同じ情報を繰り返す
return fmt.Errorf("FindByID failed: %w", fmt.Errorf("query failed: %w", err))

// GOOD: 各層で新しい文脈だけ追加
// repo層: return fmt.Errorf("query user %s: %w", id, err)
// usecase層: return fmt.Errorf("get user profile: %w", err)
// → "get user profile: query user abc123: connection refused"
```

### 3. エラーメッセージへの秘匿情報の混入

```go
// BAD: パスワードやトークンをエラーメッセージに含める
return fmt.Errorf("auth failed for user %s with password %s", user, password)

// GOOD: 識別子のみ
return fmt.Errorf("auth failed for user %s: %w", user, err)
```

---

## 参考資料

- [JetBrains - Secure Go Error Handling Best Practices](https://blog.jetbrains.com/go/2026/03/02/secure-go-error-handling-best-practices/)
- [Go Blog - Working with Errors in Go 1.13](https://go.dev/blog/go1.13-errors)
- [Rob Pike - Errors are values](https://go.dev/blog/errors-are-values)
