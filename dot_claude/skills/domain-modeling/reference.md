# ドメインモデリング リファレンス

SKILL.md の手法に対応するコード例と参考資料。

---

## ドメイン記述ミニ言語

コード実装の前段で、ユビキタス言語の四層（lexicon / syntax / semantics / pragmatics）を書き下すための半形式記述。Wlaschin『Domain Modeling Made Functional』の記法を kawasima が日本語向けに整理したもの。実行可能な DSL ではなく、**人間とドメイン専門家と AI Agent が共有する中間表現**として使う。

### 基本ルール

| 記号 | 意味 | 言語学的対応 |
|------|------|-------------|
| `data` | データ構造の定義 | lexicon（名詞）+ syntax（構成） |
| `behavior` | 振る舞いの定義 | lexicon（動詞）+ semantics（使用） |
| `=` | 定義の左辺と右辺を結ぶ | — |
| `AND` | すべての要素が必要（直積） | syntax（複合） |
| `OR` | いずれか1つの場合（直和） | syntax（分岐）+ semantics（状態） |
| `->` | 振る舞いの入力 → 出力 | semantics（事前/事後条件） |
| `?` | オプショナル（任意項目） | syntax（任意） |
| `List<...>` | 同種の要素が複数（業務上の意味、実装の配列を指定するものではない） | syntax（コレクション） |
| `//` | コメント（制約・補足） | semantics（制約の自然言語表現） |

### data の例

```text
// 単純な値: 制約はコメントで自然言語表現
data 注文番号 = 文字列  // "ORD-"で始まり、その後に10桁の数字
data 個数     = 整数   // 1以上
data キログラム = 数値  // 0.001以上

// 複合データ（AND）
data 注文 = 注文番号
  AND 顧客
  AND List<注文明細>  // 1件以上

// 分岐（OR）— 同名でも形が違うとき
data 注文数量 = 個数 OR キログラム

// 連絡手段が複数候補から1つ
data 連絡手段 = メールアドレス OR 電話番号 OR 住所
```

### behavior の例（成功と失敗を OR で明示）

```text
// 単純な変換
behavior 価格を計算する = 商品 AND 数量 -> 金額

// 失敗を OR で明示
behavior 注文を検証する = 未検証注文 -> 検証済み注文 OR 検証エラー
behavior 在庫を引き当てる = 製品コード AND 数量 -> 引当済み OR 在庫不足エラー

// 状態遷移を behavior で書く
behavior 注文を承認する = 未承認注文 AND 承認者 -> 承認済み注文 OR 承認失敗
behavior 注文を出荷する = 承認済み注文 AND 配送先 -> 出荷済み注文 OR 出荷失敗
```

### 表現指針

#### 1. フラグではなく `OR` で状態を表す

```text
# BAD: フラグで状態を表現
data 注文 = 注文番号 AND 顧客名 AND 商品リスト AND 承認済みフラグ  // true/false

# GOOD: OR で状態を分離。状態ごとに必要なデータが自然に分かれる
data 注文 = 未承認注文 OR 承認済み注文

data 未承認注文   = 注文番号 AND 顧客名 AND 商品リスト
data 承認済み注文 = 注文番号 AND 顧客名 AND 商品リスト AND 承認者 AND 承認日時
```

利点: 状態が業務用語のまま表現される / 状態ごとに必要な属性が型で分離される / 新しい状態（差し戻し、キャンセル等）を追加しやすい。

#### 2. ステータスコードではなく「型」と「遷移」を明示する

数値や文字列のステータスコード（`status: 0|1|2|3`）を、状態の `OR` 列挙と状態遷移の `behavior` で書き換える。これにより「どの状態から、どの状態へ移れるか」「その操作に何が必要か」が仕様として読み取れる。

#### 3. 分岐の条件を「名前」で表現する

`if (order.amount >= 100000)` のような条件分岐は、業務語彙が消えて数字だけが残る悪例。条件判定を behavior にして名前を与えると、後段の仕様議論がその語彙で続けられる。

```text
behavior 高額か判定する = 金額 -> 通常 OR 高額  // 高額: 金額が10万円以上
```

> 状態（ライフサイクル）と区分（その時点の分類）を区別する。前者は時間や操作で変わるもの（未承認→承認済み）、後者は同じ時点のデータを条件で分けたもの（通常/高額）。

#### 4. 安易な `?` は避ける

`?` を多用すると、業務上ありえない状態（連絡先が一切ない顧客など）を構造が許してしまう。「少なくとも1つ必須」は `OR` ではなく `List<...>` + 件数制約で書く。

```text
# BAD: 連絡先が両方 nil の状態を許してしまう
data 顧客 = 氏名 AND メールアドレス? AND 電話番号?

# GOOD: 連絡手段が必ず1つ以上ある状態を型で保証
data 顧客   = 氏名 AND 連絡先
data 連絡先 = メールアドレス OR 電話番号
```

#### 5. ほぼ同じ data は「合成」で表現する（コピペでなく）

`注文 / 注文v2 / 注文3` のような名前だけ変えたコピペは、差分の理由が記憶と命名に逃げてしまう。共通部分を切り出し、差分を `AND` で合成すると、似ている理由と違う理由が構造として読める。

差分は3層で見分ける（前を飛ばすと判断を誤る）:

1. **必須項目が違う** → 共通 `data` を抽出して `AND` で差分を合成
2. **不変条件（許されない組み合わせ）が違う** → モデル分割または制約明記
3. **業務上の役割・段階が違う** → データだけでなく振る舞いまで含めて状態として捉える（`OR` で型分離）

```text
data 注文共通     = 注文番号 AND 顧客ID AND List<注文明細>
data 未承認注文   = 注文共通 AND 見積有効期限
data 承認済み注文 = 注文共通 AND 承認者 AND 承認日時
```

### 実装段階での緩和

ミニ言語と実装は**完全一致させる必要はない**。AI Agent / 設計者が共通理解を作るための中間表現であり、以下の運用が現実的:

- ミニ言語の `data` 入れ子構造を、必ずしもその通りに型として作らなくてよい
- 振る舞いで使われないデータは、実装段階では型を切らなくてよい
- `List<...>` は業務上「複数ある」意味の記号。実装の配列・Set・Map のいずれでもよい
- 件数制約・桁数制約等はコメント。型で表現するか実装で検証するかは設計判断

### 実行可能 DSL との違い

実行可能な内部 DSL や Published Language（Evans 2015 p.36）は、**機械可読・コンパイル可能な形式言語**で、最終的にソフトウェア実装になる。これに対しミニ言語は半形式の記述言語であり、文法はあるがコンパイラ不要で、実装との対応は厳密でなくてよい。

両者は対立せず、**ミニ言語は「文法を書き下す」フェーズ、DSL は「文法の一部を機械に固定化する」フェーズ**として連続している。どこまで形式化するかは設計対象と運用体制で決める。

> **AI Agent 用システムプロンプト断片**（kawasima 提案を要約）
>
> - ドメイン層で扱うデータは業務上常に Valid であること
> - ドメイン層の振る舞いは原則として全域性を満たすこと（取りうる全入力に対し例外なく出力を返す）
> - 振る舞いの入力に「使われないデータ」を含めないこと
> - 上記2点のため必要なら型を分解する
> - 実装は必ずしもミニ言語の入れ子構造の通りに型を作らなくてよい
> - ドメイン層の型・振る舞い名は短く簡潔に。Prefix / Suffix は不要

---

## コンテキスト境界の発見: 例

### 「商品」という言葉のコンテキスト分割

| コンテキスト | アクター | 目的 | 「商品」の意味 | ルール |
|-------------|---------|------|-------------|--------|
| 在庫 | 在庫スタッフ | 棚卸し・在庫調整 | 入出庫の対象物 | 入出庫・在庫調整ルール |
| 配送 | 配送業者 | 商品の配送 | 配送物 | 配送経路・配送状況ルール |
| 販売 | 営業担当 | 販売・売上管理 | 販売対象 | 価格・割引ルール |

---

## 再構築テクニック: コード例

### 状態 → 別の型に分離（Always-Valid Model）

```typescript
// BEFORE: フラグ + ステータスで状態管理（再構築の兆候）
interface Order {
  isApproved: boolean;
  isCancelled: boolean;
  status: 0 | 1 | 2;
  shippingStartedAt?: Date;  // 状態によって必須/不要が変わる
}

// AFTER: 状態ごとに型を分離
type Order = DraftOrder | ConfirmedOrder | ShippingOrder;

type DraftOrder = { kind: "draft"; items: Item[] };
type ConfirmedOrder = { kind: "confirmed"; items: Item[]; confirmedAt: Date };
type ShippingOrder = { kind: "shipping"; items: Item[]; confirmedAt: Date; shippingStartedAt: Date };

function confirmOrder(draft: DraftOrder): ConfirmedOrder { /* ... */ }
function shipOrder(confirmed: ConfirmedOrder): ShippingOrder { /* ... */ }
```

### 振る舞いから逆算してデータを抽出（スタンプ結合の解消）

```typescript
// BEFORE: 契約オブジェクト全体を渡すが一部しか使わない
function calculateRevenue(contract: Contract): Money {
  // contract.billingMethod と contract.billingDate しか使っていない
}

// AFTER: 真に必要なデータだけを値オブジェクトとして切り出す
type BillingPolicy = { method: "lumpSum" | "installment"; billingDate: Date };

function calculateRevenue(policy: BillingPolicy): Money { /* ... */ }
```

---

## 直交性を高める分解: コード例

```typescript
// BEFORE: 非直交（全組み合わせを列挙 = 乗算的）
function getPrice(customerType: string, timeSlot: string): number {
  if (customerType === "adult" && timeSlot === "late") return 1200;
  // ... 50パターン続く
}

// AFTER: 直交（各軸が独立 = 加算的）
function getBasePrice(): number { return 1800; }
function getCustomerDiscount(type: CustomerType): number { /* 4パターン */ }
function getTimeDiscount(slot: TimeSlot): number { /* 3パターン */ }

function getPrice(type: CustomerType, slot: TimeSlot): number {
  return getBasePrice() - getCustomerDiscount(type) - getTimeDiscount(slot);
}
```

---

## ドメインサービスの完全性と純粋性: コード例

### アプローチ C: 判断をアプリ層に引き上げ（推奨）

```kotlin
// ドメインサービス: 純粋。外部依存なし。判断に必要なデータは引数で受け取る
class EmailUniquenessChecker {
    fun check(email: Email, alreadyExists: Boolean): EmailUniquenessResult {
        return if (alreadyExists) EmailUniquenessResult.Duplicate
               else EmailUniquenessResult.Unique
    }
}

// アプリケーション層: Read（Repository呼び出し）と判断（ドメインサービス）を分離
class RegisterUserUseCase(
    private val userRepo: UserRepository,
    private val checker: EmailUniquenessChecker
) {
    fun execute(command: RegisterUserCommand) {
        val exists = userRepo.existsByEmail(command.email)  // インフラ層の責務
        val result = checker.check(command.email, exists)    // 純粋なドメイン判断
        // ...
    }
}
```

### アプローチ B-2: 高階関数でインフラを隠蔽（完全性を優先する場合）

```kotlin
// ドメインサービス: Repository に直接依存しないが、関数経由で外部依存は残る
class EmailUniquenessChecker {
    fun check(email: Email, existsCheck: (Email) -> Boolean): EmailUniquenessResult {
        return if (existsCheck(email)) EmailUniquenessResult.Duplicate
               else EmailUniquenessResult.Unique
    }
}

// アプリケーション層: インフラエラーのハンドリングはここに閉じる
class RegisterUserUseCase(
    private val userRepo: UserRepository,
    private val checker: EmailUniquenessChecker
) {
    fun execute(command: RegisterUserCommand) {
        val result = checker.check(command.email) { e -> userRepo.existsByEmail(e) }
        // ...
    }
}
```

### アプローチ B-1: Repository 直接注入（簡易だが純粋性を犠牲）

```kotlin
// ドメインサービス: Repository に直接依存。インフラエラーがドメインに混入する
class EmailUniquenessChecker(private val userRepo: UserRepository) {
    fun check(email: Email): EmailUniquenessResult {
        val exists = userRepo.existsByEmail(email)  // DB接続エラーが混入
        return if (exists) EmailUniquenessResult.Duplicate else EmailUniquenessResult.Unique
    }
}
```
```

### 調整系ドメインサービス（Write 排除）+ modifiedEntities パターン

```kotlin
// ドメインサービス: 判断と生成のみ。永続化しない
class TransferPolicy {
    fun evaluate(from: Account, to: Account, amount: Money): TransferResult {
        from.withdraw(amount)  // ドメインエラーのみ発生しうる
        to.deposit(amount)
        return TransferResult.of(from, to)
    }
}

// 戻り値: 個別アクセスを封じ、保存忘れを型レベルで防止
class TransferResult private constructor(
    private val from: Account,
    private val to: Account
) {
    fun modifiedAccounts(): List<Account> = listOf(from, to)

    companion object {
        fun of(from: Account, to: Account) = TransferResult(from, to)
    }
}

// アプリケーション層: I/O の調整役
class TransferUseCase(
    private val repo: AccountRepository,
    private val policy: TransferPolicy
) {
    fun execute(command: TransferCommand) {
        val from = repo.findById(command.fromId)   // インフラエラーはここ
        val to = repo.findById(command.toId)       // インフラエラーはここ
        val result = policy.evaluate(from, to, command.amount)  // ドメインエラーだけ
        result.modifiedAccounts().forEach { repo.save(it) }     // 一括保存
    }
}
```

---

## NotebookLM ノートブック一覧

### Phase 1: モデリング中 — DDD ノートブック

**ノートブック ID**: `593bbb11-cb90-4a81-a934-9cce0474a8d5`

Bounded Context の分割、Aggregate 境界、状態遷移設計など、ドメインモデルの構造に関する設計課題を問い合わせる。

```bash
notebooklm ask "質問内容" --notebook 593bbb11-cb90-4a81-a934-9cce0474a8d5
```

**いつ使うか:**
- 初期設計: Bounded Context 分割、コンテキストマップ、Aggregate 設計
- モデル改善: 既存モデルの再構築兆候を検知した際の設計方針検証
- 判断の裏付け: 複数の設計選択肢がある場合の根拠確認

**質問の流れ（初期設計の場合）:**
1. Bounded Context の分割案（機能一覧を添えて）
2. 各コンテキスト内の Aggregate 境界（エンティティ一覧と関係を添えて）
3. ドメインイベントと状態遷移の型設計
4. Repository 層の実装パターン（言語・フレームワーク固有）

### Phase 2: モデリング後 — 別視点からの設計レビュー

**ノートブック ID**: `17a88c4a-8e2d-46b8-9cda-ffd6a7f84519`（CQRS/ES）

ドメインモデルが固まった後、実装に移る前に別の視座から設計を揺さぶる。DDD の枠内では見えない改善点（並行性、イベント配信、読み書き分離）を発見するためのフェーズ。

```bash
notebooklm ask "質問内容" --notebook 17a88c4a-8e2d-46b8-9cda-ffd6a7f84519
```

**いつ使うか:**
- ドメインイベントを使う設計が確定した後（イベント配信の信頼性・パターン選定）
- 1つの集約に複数の非同期プロセスが書き込む構造が見えた時（ロック競合の予兆）
- 読み取りと書き込みのアクセスパターンが大きく異なる時

**問いの例:**
- 「この集約設計で、AI の非同期処理3つが並行更新する。楽観ロック競合を避ける軽量なアプローチは？」
- 「ドメインイベントを ApplicationEventPublisher で発行しているが、信頼性の問題はないか？」
- 「この Read/Write パターンに対して CQRS の Read Model 分離は妥当か？Event Sourcing まで必要か？」

---

## 参考資料

- [kawasima - ユビキタス言語](https://scrapbox.io/kawasima/%E3%83%A6%E3%83%93%E3%82%AD%E3%82%BF%E3%82%B9%E8%A8%80%E8%AA%9E) — UL の四層構造、用語集との分かれ目、訳語「同じ言葉」の罠、失敗モード5項目、tactical pattern バイアス批判の出典
- [kawasima - ドメイン記述ミニ言語](https://scrapbox.io/kawasima/%E3%83%89%E3%83%A1%E3%82%A4%E3%83%B3%E8%A8%98%E8%BF%B0%E3%83%9F%E3%83%8B%E8%A8%80%E8%AA%9E) — 本ファイル「ドメイン記述ミニ言語」セクションの一次出典
- [Domain Modeling Made Functional](https://pragprog.com/titles/swdddf/domain-modeling-made-functional/)
- [広木大地 - スケールする要求を支える仕様の「意図」と「直交性」](https://qiita.com/hirokidaichi/items/61ad129eae43771d0fc3)
- [kawasima - 型の粒度設計](https://scrapbox.io/kawasima/%E5%9E%8B%E3%81%AE%E7%B2%92%E5%BA%A6%E8%A8%AD%E8%A8%88)
- MinoDriven - 言語ゲーム・脱構築・スキーマ理論を活用した境界付けられたコンテキストの発見手法
