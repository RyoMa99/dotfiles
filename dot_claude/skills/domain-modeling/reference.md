# ドメインモデリング リファレンス

SKILL.md の詳細なコード例・チェックリスト・参考資料。

---

## 直交性を高める分解: コード例

```typescript
// BAD: 非直交（全組み合わせを列挙 = 乗算的）
function getPrice(customerType: string, timeSlot: string, day: string): number {
  if (customerType === "adult" && timeSlot === "late" && day === "weekday") return 1200;
  if (customerType === "adult" && timeSlot === "late" && day === "weekend") return 1400;
  // ... 50パターン続く
}

// GOOD: 直交（各軸が独立 = 加算的）
function getBasePrice(): number { return 1800; }
function getCustomerDiscount(type: CustomerType): number { /* 4パターン */ }
function getTimeDiscount(slot: TimeSlot): number { /* 3パターン */ }
function getSpecialPrice(date: Date): number | null { /* 例外: 映画の日 */ }

function getPrice(type: CustomerType, slot: TimeSlot, date: Date): number {
  const special = getSpecialPrice(date);
  if (special !== null) return special;
  return getBasePrice() - getCustomerDiscount(type) - getTimeDiscount(slot);
}
```

---

## ベストプラクティス: コード例

### 1. フラグ廃止 → OR導入

```typescript
// BAD: フラグで状態を表現
interface Order {
  isApproved: boolean;
  isCancelled: boolean;
  isShipped: boolean;
}

// GOOD: ORで状態を表現
type Order = PendingOrder | ApprovedOrder | CancelledOrder | ShippedOrder;

interface PendingOrder {
  kind: "pending";
  items: Item[];
  orderedAt: Date;
}

interface ApprovedOrder {
  kind: "approved";
  items: Item[];
  orderedAt: Date;
  approvedAt: Date;
  approvedBy: UserId;
}
```

### 2. ステータスコード廃止 → 型と遷移の明示

```typescript
// BAD: 数値コードで状態管理
interface Order {
  status: 0 | 1 | 2; // 0:下書き、1:未承認、2:承認済み
}

// GOOD: 型で状態を定義し、振る舞いで遷移を明示
type DraftOrder = { kind: "draft"; /* ... */ };
type PendingOrder = { kind: "pending"; /* ... */ };
type ApprovedOrder = { kind: "approved"; /* ... */ };

function submitOrder(draft: DraftOrder): PendingOrder { /* ... */ }
function approveOrder(pending: PendingOrder): ApprovedOrder { /* ... */ }
```

### 3. 条件判定に名前付与

```typescript
// BAD: マジックナンバーが埋もれる
function processOrder(order: Order) {
  if (order.totalAmount > 100000) {
    requireManagerApproval(order);
  }
}

// GOOD: 条件判定に名前を付ける
type AmountCategory = "normal" | "highValue";

function categorizeAmount(amount: number): AmountCategory {
  return amount > 100000 ? "highValue" : "normal";
}
```

### 4.「ほぼ同じdata」の整理

**必須項目が異なる場合**: 共通部分を抽出しANDで合成

```typescript
interface OrderBase {
  items: Item[];
  customerId: CustomerId;
}

type DraftOrder = OrderBase & { kind: "draft" };
type SubmittedOrder = OrderBase & { kind: "submitted"; submittedAt: Date };
```

**局所的な選択肢**: 差分をORに閉じ込める

```typescript
type PaymentMethod = CreditCard | BankTransfer | CashOnDelivery;

interface Order {
  items: Item[];
  payment: PaymentMethod;
}
```

**段階・責務の違い**: 状態として分離

```typescript
type UnvalidatedOrder = { /* 生データ */ };
type ValidatedOrder = { /* 検証済みデータ */ };

function validateOrder(input: UnvalidatedOrder): ValidatedOrder | ValidationError {
  // ...
}
```

### 5. 不変条件設計

```typescript
// BAD: オプショナルで曖昧に
interface Customer {
  name: string;
  email?: string;
  phone?: string;
}

// GOOD: 不変条件を型で強制
type ContactInfo = { kind: "email"; email: Email } | { kind: "phone"; phone: Phone };

interface Customer {
  name: Name;
  contact: ContactInfo;  // 必ず1つは必要
}
```

---

## 振る舞い定義: コード例

```typescript
// ドメイン記述: 検証する = 未検証データ -> 検証済みデータ OR 検証エラー
type ValidationResult = ValidatedData | ValidationError;

function validate(input: UnvalidatedData): ValidationResult {
  // 例外に頼らず、すべての入力に対して出力が保証される（全域性）
}
```

### OR vs List の使い分け

```typescript
// OR: いずれか1つ（排他的）
type Contact = Email | Phone;  // 両方持てない

// List: 複数を同時に持てる（「少なくとも1つ」）
type NonEmptyArray<T> = [T, ...T[]];
type Contacts = NonEmptyArray<ContactMethod>;
```

---

## 型の粒度設計: コード例

### 配送方法選択

```typescript
// BAD: 条件をコード内にハードコード
function getShippingMethods(amount: number, region: string) {
  if (amount >= 5000 && region === "domestic") {
    return ["standard", "express", "nextday"];
  }
  // ...複雑な条件分岐
}

// GOOD: 区分を型で表現
type AmountCategory = "under5000" | "5000to10000" | "over10000";
type RegionCategory = "domestic" | "remote" | "international";
type ShippingMethod = "standard" | "express" | "nextday";

function getAvailableMethods(
  amount: AmountCategory,
  region: RegionCategory
): ShippingMethod[] {
  // 組み合わせごとに明確に定義
}
```

### 会員ランク（パラメータ化）

```typescript
// BAD: 固定列挙（変更のたびにコード修正）
type MemberRank = "bronze" | "silver" | "gold";

// GOOD: パラメータ化（データで定義）
interface RankDefinition {
  name: string;
  minSpending: number;
  discountRate: number;
  freeShippingThreshold: number;
}

const ranks: RankDefinition[] = [
  { name: "bronze", minSpending: 0, discountRate: 0.05, freeShippingThreshold: 5000 },
  { name: "silver", minSpending: 10000, discountRate: 0.10, freeShippingThreshold: 3000 },
  { name: "gold", minSpending: 50000, discountRate: 0.15, freeShippingThreshold: 0 },
];
```

### BMI判定（連続値の区分化）

```typescript
// Step 1: 出力は列挙可能か？ → No（BMI自体は連続値）
// Step 2: 結果カテゴリに差異があるか？ → Yes（医学的基準で3区分）

type BmiCategory = "underweight" | "normal" | "overweight";

function categorizeBmi(bmi: number): BmiCategory {
  if (bmi < 18.5) return "underweight";
  if (bmi < 25) return "normal";
  return "overweight";
}

function getHealthAdvice(category: BmiCategory): string {
  switch (category) {
    case "underweight": return "栄養摂取を増やしましょう";
    case "normal": return "現状維持を心がけましょう";
    case "overweight": return "運動と食事管理を推奨します";
  }
}
```

### テストへの活用

定義した区分は**同値分割法の同値クラス**として直接利用できる。

```typescript
// 配送方法の例: 3(金額区分) × 3(地域区分) = 9パターン
describe("getAvailableMethods", () => {
  it.each([
    ["under5000", "domestic", ["standard"]],
    ["under5000", "remote", ["standard"]],
    ["under5000", "international", []],
    ["5000to10000", "domestic", ["standard", "express"]],
    // ...全9パターン
  ])("金額=%s, 地域=%s → %s", (amount, region, expected) => {
    expect(getAvailableMethods(amount, region)).toEqual(expected);
  });

  // 境界値テスト
  it("4999円は under5000", () => {
    expect(categorizeAmount(4999)).toBe("under5000");
  });
  it("5000円は 5000to10000", () => {
    expect(categorizeAmount(5000)).toBe("5000to10000");
  });
});
```

---

## チェックリスト

### ドメインモデリング
- [ ] 仕様表の背後に隠れた意図（WHY）を発見したか
- [ ] 仕様の軸が直交しているか（変更が他の軸に波及しないか）
- [ ] フラグをORに置き換えられないか
- [ ] ステータスコードを型と遷移で表現できないか
- [ ] 条件判定（マジックナンバー）に名前を付けたか
- [ ] 「ほぼ同じdata」を適切に整理したか
- [ ] 不変条件を型で強制しているか
- [ ] 振る舞いの失敗ケースをORで明示したか
- [ ] ORとListを適切に使い分けているか

### 型の粒度設計
- [ ] 出力の列挙可能性を確認したか
- [ ] 結果カテゴリごとの差異（不変条件、後続処理、境界値）を検証したか
- [ ] 入力のOR区分と中間区分型を適切に選択したか
- [ ] 固定列挙とパラメータ化を適切に選択したか
- [ ] 区分を同値クラスとしてテストに活用したか

---

## 参考資料

- [kawasima - ドメイン記述ミニ言語](https://scrapbox.io/kawasima/%E3%83%89%E3%83%A1%E3%82%A4%E3%83%B3%E8%A8%98%E8%BF%B0%E3%83%9F%E3%83%8B%E8%A8%80%E8%AA%9E)
- [Domain Modeling Made Functional](https://pragprog.com/titles/swdddf/domain-modeling-made-functional/)
- [広木大地 - スケールする要求を支える仕様の「意図」と「直交性」](https://qiita.com/hirokidaichi/items/61ad129eae43771d0fc3)
- [kawasima - 型の粒度設計](https://scrapbox.io/kawasima/%E5%9E%8B%E3%81%AE%E7%B2%92%E5%BA%A6%E8%A8%AD%E8%A8%88)
- MinoDriven - 言語ゲーム・脱構築・スキーマ理論を活用した境界付けられたコンテキストの発見手法
