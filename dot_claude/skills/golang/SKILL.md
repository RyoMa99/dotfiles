---
name: golang
description: "Use when developing Go applications - error handling, logging, concurrency patterns, and testing. Triggers on Go code editing, module setup, or when discussing Go-specific design decisions like error propagation, structured logging with slog, or goroutine management."
---

参照ファイル:
- `error-handling.md` — セキュアなエラーハンドリング、Split-Brain Error Types、Opaque Wrapping
- `logging.md` — slog による構造化ログ、LogValuer、Canonical Log Lines

# Go 設計原則

関連: `robust-code.md` ルール（型による予防的設計）
関連: `layered-architecture.md`（三層＋ドメインモデル）

---

## エラーハンドリングの核心

### エラーは値

Go のエラーは例外ではなく値。各呼び出し箇所で明示的に処理する必要がある。これはセキュリティリスクにも直結する（内部情報の漏洩）。

### エラー設計の判断フロー

```
エラーをどう設計するか？
    ↓
呼び出し元がエラーの種類を判別する必要がある？
    ├─ No → fmt.Errorf でラップして返す
    └─ Yes → エラーの種類はいくつ？
              ├─ 少数（2-3） → Sentinel Error（var ErrNotFound = errors.New(...)）
              └─ 多数 or コンテキスト付き → カスタムエラー型（struct）
                    └─ ユーザーに見せるメッセージが必要？
                          ├─ Yes → Split-Brain Error Types（詳細は error-handling.md）
                          └─ No → 通常のカスタムエラー型
```

### エラーラップの原則

```go
// BAD: コンテキストなしで返す
return err

// BAD: fmt.Errorf で %v（errors.Is/As が壊れる）
return fmt.Errorf("failed: %v", err)

// GOOD: %w でラップしてコンテキストを追加
return fmt.Errorf("fetch user %s: %w", userID, err)
```

ラップ時のメッセージは「何をしようとしていたか」を簡潔に記述する。呼び出しスタックの各層で文脈を追加することで、エラーメッセージ全体がデバッグに役立つトレースになる。

詳細は `error-handling.md` を参照。

---

## ログ設計の核心

### slog を標準とする

Go 1.21 以降、`log/slog` が標準ライブラリに含まれる。サードパーティ（zap, zerolog 等）より slog を優先する。

### ログレベルの使い分け

| レベル | 用途 | 例 |
|--------|------|-----|
| **Debug** | 開発時の詳細情報 | SQL クエリ、リクエスト/レスポンス詳細 |
| **Info** | 正常な業務イベント | ユーザー登録完了、注文処理開始 |
| **Warn** | 想定内だが注意が必要 | リトライ発生、非推奨 API の使用 |
| **Error** | 処理の失敗 | DB 接続失敗、外部 API タイムアウト |

### ログに含めるべき構造化フィールド

```go
slog.Info("order processed",
    "order_id", order.ID,
    "user_id", order.UserID,
    "amount", order.Total,
    "duration_ms", elapsed.Milliseconds(),
)
```

詳細は `logging.md` を参照。

---

## プロジェクト構成

### Standard Go Project Layout の要点

```
project/
├── cmd/                  # エントリポイント（main パッケージ）
│   └── server/
│       └── main.go
├── internal/             # 外部から import 不可（Go コンパイラが強制）
│   ├── domain/           # ドメインモデル（エンティティ、値オブジェクト）
│   ├── usecase/          # アプリケーションサービス（ユースケース）
│   ├── handler/          # プレゼンテーション層（HTTP ハンドラ）
│   └── infra/            # データソース層（DB、外部 API）
├── pkg/                  # 外部に公開してよいライブラリ（慎重に）
├── go.mod
└── go.sum
```

`internal/` は Go コンパイラが import 制限を強制するため、`layered-architecture.md` の依存方向を構造的に保証できる。

### パッケージ設計

```
パッケージの責務が明確か？
    ├─ Yes → パッケージ名は「何を提供するか」で命名（user, order, auth）
    └─ No → パッケージが大きすぎる
              → 機能単位で分割する
```

| 原則 | 説明 |
|------|------|
| **名前は単数形** | `users` ではなく `user` |
| **util / common 禁止** | 責務が不明確。具体的な名前を付ける |
| **循環 import 禁止** | Go コンパイラがエラーにする。interface で依存を逆転 |

---

## Interface 設計

### Accept interfaces, return structs

```go
// GOOD: 引数は interface（依存性逆転）
func ProcessOrder(repo OrderRepository, order *Order) error {
    return repo.Save(order)
}

// GOOD: 戻り値は具象型（利用者が柔軟に使える）
func NewOrderService(repo OrderRepository) *OrderService {
    return &OrderService{repo: repo}
}
```

### Interface は利用者側で定義する

```go
// BAD: 実装側で大きな interface を定義
// package repository
type UserRepository interface {
    FindByID(id string) (*User, error)
    FindAll() ([]*User, error)
    Save(user *User) error
    Delete(id string) error
    // ... 20メソッド
}

// GOOD: 利用者側で必要なメソッドだけ定義
// package usecase
type UserFinder interface {
    FindByID(id string) (*User, error)
}

func GetUser(finder UserFinder, id string) (*User, error) {
    return finder.FindByID(id)
}
```

---

## テスト

### Table-Driven Tests

```go
func TestParseEmail(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    Email
        wantErr bool
    }{
        {name: "valid", input: "user@example.com", want: Email("user@example.com")},
        {name: "empty", input: "", wantErr: true},
        {name: "no_at", input: "userexample.com", wantErr: true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseEmail(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("ParseEmail(%q) error = %v, wantErr %v", tt.input, err, tt.wantErr)
                return
            }
            if got != tt.want {
                t.Errorf("ParseEmail(%q) = %v, want %v", tt.input, got, tt.want)
            }
        })
    }
}
```

### testify の使い分け

| パッケージ | 用途 |
|-----------|------|
| `assert` | テスト失敗時も後続を実行（`t.Error` 相当） |
| `require` | テスト失敗時に即停止（`t.Fatal` 相当）。前提条件の検証に |

```go
// 前提条件: require（失敗したら後続は意味がない）
require.NoError(t, err)
require.NotNil(t, user)

// 検証: assert（複数の検証を一度に確認）
assert.Equal(t, "Alice", user.Name)
assert.Equal(t, "alice@example.com", user.Email)
```

---

## チェックリスト

Go コードレビュー時に確認：

### エラーハンドリング
- [ ] エラーを無視していないか（`_ = doSomething()` の正当な理由があるか）
- [ ] `%w` でラップしてコンテキストを追加しているか
- [ ] ユーザーに返すエラーに内部情報が含まれていないか
- [ ] Sentinel Error と カスタムエラー型を適切に使い分けているか

### ログ
- [ ] 構造化フィールドを使っているか（文字列結合ではなく key-value）
- [ ] 秘匿情報（パスワード、トークン）がログに含まれていないか
- [ ] ログレベルが適切か（正常系を Error にしていないか）

### 設計
- [ ] `internal/` で外部公開を制限しているか
- [ ] interface は利用者側で定義しているか
- [ ] パッケージ間の循環依存がないか

### テスト
- [ ] Table-Driven Tests で網羅的にテストしているか
- [ ] `require` と `assert` を適切に使い分けているか
- [ ] テストヘルパーに `t.Helper()` を付けているか
