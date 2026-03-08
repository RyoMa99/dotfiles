# ドメインモデリング リファレンス

SKILL.md の手法に対応するコード例と参考資料。

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

- [kawasima - ドメイン記述ミニ言語](https://scrapbox.io/kawasima/%E3%83%89%E3%83%A1%E3%82%A4%E3%83%B3%E8%A8%98%E8%BF%B0%E3%83%9F%E3%83%8B%E8%A8%80%E8%AA%9E)
- [Domain Modeling Made Functional](https://pragprog.com/titles/swdddf/domain-modeling-made-functional/)
- [広木大地 - スケールする要求を支える仕様の「意図」と「直交性」](https://qiita.com/hirokidaichi/items/61ad129eae43771d0fc3)
- [kawasima - 型の粒度設計](https://scrapbox.io/kawasima/%E5%9E%8B%E3%81%AE%E7%B2%92%E5%BA%A6%E8%A8%AD%E8%A8%88)
- MinoDriven - 言語ゲーム・脱構築・スキーマ理論を活用した境界付けられたコンテキストの発見手法
