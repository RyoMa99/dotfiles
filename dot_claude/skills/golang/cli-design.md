# Go CLI 設計原則

GopherCon 2019 "Design Command-Line Tools People Love" (Carolyn Van Slyck) の知見をベースにした原則集。
cobra を前提とするが、考え方は他の CLI フレームワークにも適用できる。

参考: https://www.youtube.com/watch?v=eMz0vni6PAw

---

## cobra はただの配線

cobra の `RunE` にビジネスロジックを書かない。cobra が担うのは:
- フラグ解析・引数バリデーション
- ヘルプテキスト生成
- サブコマンドのルーティング

ロジックは `internal/app` パッケージの `App` struct メソッドに置く。

```go
// BAD: ロジックが cobra に埋まっている
cmd := &cobra.Command{
    Use: "fetch",
    RunE: func(cmd *cobra.Command, args []string) error {
        // 50行のビジネスロジック...
    },
}

// GOOD: cobra は App のメソッドを呼ぶだけ
cmd := &cobra.Command{
    Use: "fetch",
    RunE: func(cmd *cobra.Command, args []string) error {
        return a.Fetch(cmd.Context(), fetchOpts)
    },
}
```

### なぜ分離するか

- **テスタビリティ**: App のメソッドを直接テストでき、cobra のコマンドツリーを組み立てる必要がない
- **再利用性**: `package main` の外にあるので、他のツールやライブラリから呼べる
- **保守性**: cobra を知らないチームメンバーもロジック部分に貢献できる

---

## NewRootCmd() ファクトリパターン

グローバル変数 `var rootCmd = &cobra.Command{...}` は避ける。テスト間で状態が共有される。

```go
// GOOD: 毎回新しいコマンドツリーを生成
func NewRootCmd() *cobra.Command {
    app := app.New()
    cmd := &cobra.Command{
        Use:   "mytool",
        Short: "ツールの説明",
    }
    cmd.AddCommand(newFetchCmd(app))
    return cmd
}
```

テストでは `NewRootCmd()` を呼ぶだけで独立したコマンドツリーが手に入る。

---

## 設定を struct に閉じ込める

viper 等の設定ライブラリは専用パッケージ（`internal/config`）に隔離する。

```go
// internal/config/config.go
type Config struct {
    Feeds    []Feed        `mapstructure:"feeds"`
    Timeout  time.Duration `mapstructure:"timeout"`
}

func Load(path string) (Config, error) {
    // viper はここだけ。外に漏らさない
}
```

- `PreRunE` で設定読み込み・バリデーション
- `RunE` ではバリデーション済みの `Config` struct だけを使う
- App struct も `Config` struct を受け取る（viper に依存しない）

---

## コマンドの文法

### 位置引数は「名前」だけ

位置引数の順序をユーザーに覚えさせない。名前（識別子）以外はフラグにする。

```bash
# GOOD: 位置引数は名前だけ
go-feed fetch             # フィード名なし = 全件
go-feed list economy      # カテゴリ名

# BAD: 異なる型の位置引数が混在（順序を覚える必要がある）
go-feed add https://example.com/rss economy rss
#           ^URL                   ^category ^type → 全部フラグにすべき
```

### 同じ型の複数引数は位置引数 OK

```bash
# GOOD: 全部フィード名（同じ型）
go-feed fetch tech economy finance
```

### 声に出して自然に言えるか

コマンドを設計したら、まず声に出して読む。不自然なら設計を見直す。

```bash
# 自然: "go-feed fetch"（go-feed でフィードを取得）
# 自然: "go-feed list --category tech"（techカテゴリを一覧）
# 不自然: "go-feed get-articles-from-feeds"（冗長）
```

---

## 出力のデュアルモード

デフォルトは人間向け。最短コマンドが人間向け出力になるようにする。

```bash
# 人間向け（デフォルト）
go-feed list
# Title                  Published     Source
# Go 1.26 Released       2 hours ago   golang-blog
# ...

# 機械向け（明示的に指定）
go-feed list --output json
```

- 人間向け: 日時は相対表記（`2 hours ago`）、テーブル整形
- 機械向け: JSON、ISO 8601 日時、全フィールド出力

---

## ヘルプテキストのカスタマイズ

cobra が自動生成するヘルプ（コマンド一覧・フラグ一覧）は最低限の情報。
ユーザーが成功するために必要な情報を `Example` フィールドに追加する。

```go
cmd := &cobra.Command{
    Use:   "fetch",
    Short: "フィードを取得して記事を出力する",
    Example: `  # 全フィードを取得
  go-feed fetch

  # 設定ファイルを指定
  go-feed fetch --config ~/.config/go-feed/config.yaml`,
}
```

---

## エコシステムの先例に従う

同じエコシステムの他ツールが使っている動詞・パターンに合わせる。
ユーザーの「指の記憶」を活かせる。

ただし、動作が異なるのに同じ動詞を使うのは逆効果。
動作が異なるなら意図的に別の動詞を選び、ユーザーに「これは違う」と伝える。
