---
name: golang
description: "Use when developing Go applications - error handling, logging, concurrency patterns, transactions, and testing. Triggers on Go code editing, module setup, or when discussing Go-specific design decisions like error propagation, structured logging with slog, goroutine management, repository/transaction patterns, or Unit of Work."
---

参照ファイル:
- `error-handling.md` — セキュアなエラーハンドリング、Split-Brain Error Types、Opaque Wrapping
- `logging.md` — slog による構造化ログ、LogValuer、Canonical Log Lines
- `cli-design.md` — cobra CLI 設計原則（ロジック分離、NewRootCmd ファクトリ、設定隔離、コマンド文法、出力モード）

# Go プロジェクト固有の選択

一般原則（エラーラップ、テーブル駆動テスト、interface 設計、パッケージ構成等）は Go 公式ドキュメントに従う。
ここでは複数の選択肢がある箇所での判断基準と、一般原則にない知見を記載する。

関連: `robust-code.md`（型による予防的設計）
関連: `layered-architecture.md`（三層＋ドメインモデル）

---

## エラー設計の判断フロー

```
呼び出し元がエラーの種類を判別する必要がある？
    ├─ No → fmt.Errorf でラップして返す
    └─ Yes → エラーの種類はいくつ？
              ├─ 少数（2-3） → Sentinel Error（var ErrNotFound = errors.New(...)）
              └─ 多数 or コンテキスト付き → カスタムエラー型（struct）
                    └─ ユーザーに見せるメッセージが必要？
                          ├─ Yes → Split-Brain Error Types（詳細は error-handling.md）
                          └─ No → 通常のカスタムエラー型
```

---

## テスト

### testify は使わない

標準ライブラリのみ。`t.Fatalf`（前提条件、失敗で即停止）と `t.Errorf`（検証、後続も実行）を使い分ける。

```go
// 前提条件: t.Fatal（失敗したら後続は意味がない）
if err != nil {
    t.Fatalf("unexpected error: %v", err)
}

// 検証: t.Errorf（複数の検証を一度に確認）
if user.Name != "Alice" {
    t.Errorf("Name = %q, want %q", user.Name, "Alice")
}
```

### 最初からテーブル駆動テスト + t.Run

ケースが1つでもテーブル駆動で書く。結局ケースは増えるので、最初から構造化しておく。

```go
func TestXxx(t *testing.T) {
    tests := []struct {
        name string
        // 入力・期待値
    }{
        {"正常系", ...},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // テスト本体
        })
    }
}
```

---

## トランザクション管理: DBTX + Unit of Work

### 段階的な導入判断

```
トランザクションが複数の Repository をまたぐか？
    │
    ├─ No → Stage 2: 単一 Repository のトランザクション
    │        Repository interface に Tx メソッドを追加
    │        大半のケースはここで十分
    │
    └─ Yes → まず集約境界を疑う
              │
              ├─ 集約を見直せば1つに収まる → Stage 2
              ├─ 結果整合性（イベント駆動）で済む → Stage 2 + 非同期処理
              └─ 即時の原子性が必要 → Stage 3: Unit of Work
```

### Stage 2: 単一 Repository のトランザクション

Repository interface にコールバック形式の `Tx` メソッドを追加。

```go
type BookStore interface {
    Get(ctx context.Context, id int64) (Book, error)
    DecrementStock(ctx context.Context, id int64) error
    Tx(ctx context.Context, fn func(BookStore) error) error
}
```

### Stage 3: Unit of Work

複数 Repository を単一トランザクションで束ねる。UoW が1つの `*sql.Tx` から全 Store を構築し、原子性を保証する。

```go
type Stores struct {
    Books  book.Store
    Orders order.Store
}

type UnitOfWork interface {
    RunInTx(ctx context.Context, fn func(Stores) error) error
}
```

UoW の実装はデータソース層に配置する（`layered-architecture.md` の依存性逆転）。

### ctx 経由のトランザクション伝播は避ける

`context.WithValue` でトランザクションを伝播させるパターン（Transactor パターン）は、型安全性が失われ、トランザクション境界が暗黙的になる。明示的な引数渡し（DBTX / UoW コールバック）を優先する。

---

## 参考

- [rednafi - Repositories, transactions, and unit of work in Go](https://rednafi.com/go/repo-txn-uow/) — DBTX + UoW パターンの段階的導入
