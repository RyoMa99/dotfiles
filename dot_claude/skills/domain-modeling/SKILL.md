---
name: domain-modeling
description: "ドメインモデリングと型の粒度設計。仕様の直交性、意図の発見、OR/AND記法、型の4段階判断フロー。設計・計画フェーズで参照。"
disable-model-invocation: false
---

# ドメインモデリング

「Domain Modeling Made Functional」に基づくドメイン記述手法。kawasima氏による解説を参考。

関連: @~/.claude/rules/robust-code.md（型による予防的設計、完全性）

---

## 核心思想

> 業務ルールを構造として、**コード以前のレベルで明確にする**

ドメイン記述ミニ言語を使って仕様を整理し、それを型に落とし込む。

---

## 意図の発見

### なぜ「意図（WHY）」が必要か

要求文書の WHY（背景・意図）は単なるコミュニケーション補助ではなく、**実装設計に直接影響する**。
意図が明確な要求からはドメインモデルという抽象構造が発見しやすくなり、将来の変更要求への対応力が向上する。

### 存在論的抽象 vs 目的論的抽象

| 分類 | 説明 | 例 |
|------|------|-----|
| **存在論的抽象** | 自明な分類（見た目で分かる） | 「大人」「子供」「シニア」 |
| **目的論的抽象** | ビジネス目的に基づく分類 | 「基本料金に対する顧客区分割引」 |

存在論的分類は誰でもできるが、それだけでは仕様が爆発する。
**目的論的抽象を発見する**ことで、仕様を少数の直交した軸に分解できる。

### 仕様表のリバースエンジニアリング

既存の仕様表（料金表、権限表など）が与えられた場合、そのまま実装するのではなく**隠れた意図を逆算**する。

```
ケーススタディ: 映画館の料金表（広木大地氏）

Before: 50パターンの料金表（顧客種別 × 時間帯 × 曜日...）
  ↓ 隠れた意図を発見
After: 3つの直交した軸 + 1つの例外 = 13パターン
  - 基本料金
  - 顧客区分割引（大人/学生/子供/シニア）
  - 時間帯割引（レイトショー/モーニング等）
  - 例外: 映画の日
```

**手順**:
1. 仕様表を眺め、パターンの背後にある「なぜこの値なのか」を問う
2. 独立した軸（直交する関心事）を見つける
3. 各軸を個別の型・関数として分離する
4. 組み合わせで元の仕様表を再現できるか検証する

---

## 仕様の直交性

### 直交性とは

機能（仕様の軸）同士が**無関係に独立して動作する**状態。

| 直交性 | 複雑性の増加 | 例 |
|--------|------------|-----|
| **高い**（独立） | **加算的**: A + B + C | 顧客区分割引と時間帯割引が独立 |
| **低い**（依存） | **乗算的**: A × B × C | 顧客種別と時間帯の全組み合わせが個別定義 |

### 直交性が低い兆候

- 仕様表が巨大なマトリクス（全組み合わせを列挙）
- 1つの変更が複数の仕様に波及する
- 「◯◯の場合は△△だが、□□のときは例外」が多数

### 直交性を高める分解

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

## 基本記法

| 記号 | 意味 | 例 |
|------|------|-----|
| `AND` | すべて必須 | `顧客 = 氏名 AND 連絡先` |
| `OR` | いずれか1つ | `連絡先 = メール OR 電話` |
| `->` | 入力から出力への変換 | `注文を承認する = 未承認注文 -> 承認済み注文` |
| `?` | オプション（使用注意） | `ニックネーム?` |

---

## データ定義の3段階

### 1. 単純な値（制約付き基本型）

```
名前 = 文字列 (2〜100文字)
金額 = 正の整数 (円単位)
メールアドレス = 文字列 (RFC準拠)
```

### 2. 複合データ（ANDで組み合わせ）

```
顧客 = 氏名 AND 連絡先 AND 住所
注文 = 顧客 AND 商品リスト AND 注文日時
```

### 3. コレクション

```
商品リスト = List<商品> (1件以上)
```

---

## 5つのベストプラクティス

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

**利点**: 状態の意味が明確、状態追加時の拡張性向上、不正な状態の組み合わせを防止。

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

// 遷移: どの状態から何ができるかが仕様として読み取れる
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

function processOrder(order: Order) {
  const category = categorizeAmount(order.totalAmount);
  if (category === "highValue") {
    requireManagerApproval(order);
  }
}
```

### 4.「ほぼ同じdata」の整理

3つの観点で差分を分類する。

**必須項目が異なる場合**: 共通部分を抽出しANDで合成

```typescript
// 共通部分
interface OrderBase {
  items: Item[];
  customerId: CustomerId;
}

// 差分をANDで合成
type DraftOrder = OrderBase & { kind: "draft" };
type SubmittedOrder = OrderBase & { kind: "submitted"; submittedAt: Date };
```

**局所的な選択肢**: 差分をORに閉じ込める

```typescript
// 支払い方法の部分だけがOR
type PaymentMethod = CreditCard | BankTransfer | CashOnDelivery;

interface Order {
  items: Item[];
  payment: PaymentMethod;
}
```

**段階・責務の違い**: 状態として分離

```typescript
// 検証前と検証後は別の型
type UnvalidatedOrder = { /* 生データ */ };
type ValidatedOrder = { /* 検証済みデータ */ };

function validateOrder(input: UnvalidatedOrder): ValidatedOrder | ValidationError {
  // ...
}
```

### 5. 不変条件設計

「連絡先がない顧客は許容しない」という要件を型で強制する。

```typescript
// BAD: オプショナルで曖昧に
interface Customer {
  name: string;
  email?: string;  // なくてもいい？
  phone?: string;  // なくてもいい？
}

// GOOD: 不変条件を型で強制
type ContactInfo = { kind: "email"; email: Email } | { kind: "phone"; phone: Phone };

interface Customer {
  name: Name;
  contact: ContactInfo;  // 必ず1つは必要
}
```

---

## 振る舞い定義

基本形は `入力 -> 出力`。成功と失敗はORで明示する。

```typescript
// ドメイン記述
// 検証する = 未検証データ -> 検証済みデータ OR 検証エラー

// コード
type ValidationResult = ValidatedData | ValidationError;

function validate(input: UnvalidatedData): ValidationResult {
  // 例外に頼らず、すべての入力に対して出力が保証される（全域性）
}
```

### 全域性のメリット

- 呼び出し側が失敗ケースを明示的に処理
- 例外による暗黙の制御フローを排除
- 型チェッカーが網羅性を検証

---

## OR vs List の使い分け

```
// OR: いずれか1つ（排他的）
連絡手段 = メール OR 電話 OR FAX

// List: 複数を同時に持てる
連絡手段リスト = List<連絡手段>
```

「少なくとも1つ」はORではなくListで表現する。

```typescript
// BAD: ORで「少なくとも1つ」を表現しようとする
type Contact = Email | Phone;  // 両方持てない

// GOOD: 非空リストで「少なくとも1つ」を表現
type NonEmptyArray<T> = [T, ...T[]];
type Contacts = NonEmptyArray<ContactMethod>;
```

---

## 型の粒度設計

kawasima氏の知見に基づく、振る舞いの境界を型として明示する設計手法。

関連: @~/.claude/rules/robust-code.md（型による予防的設計）

### 核心思想

> 「区分」とは業務の区分値コードではなく、
> **型システムにおける直和型（OR）の各選択肢**である。

代数的データ型のバリアントに相当する概念。

---

### 4段階の判断フロー

型の粒度を決定する際の判断プロセス。

#### Step 1: 出力は列挙可能か？

仕様で有限個の選択肢として明示されているか確認する。

- 表、固定文言、直和型での列挙形式を検出
- **Yes** → Step 3へ
- **No** → Step 2へ

#### Step 2: 結果カテゴリに差異があるか？

以下のいずれかが異なるか確認する：

- **不変条件**: カテゴリごとに成り立つべき制約
- **後続処理**: カテゴリによって処理が分岐
- **境界値**: カテゴリを分ける閾値

**Yes（いずれかが異なる）** → 区分を作成
**No（すべて同じ）** → 区分化は不要

#### Step 3: 型定義方法の選択

| パターン | 説明 | 使用場面 |
|----------|------|----------|
| **A: 入力をORで区分** | 各ケースで異なる処理 | 分岐ロジックが複雑 |
| **B: 中間の区分型を導入** | 全ケースで同じ処理 | 結果の種類を表現 |

#### Step 4: 固定列挙 vs パラメータ化

| 固定列挙 | パラメータ化 |
|----------|--------------|
| 有限・確定 | 多数・頻繁な変更 |
| 変更頻度が低い | 均質な処理 |
| コードで定義 | データで定義 |

---

### 型の粒度設計: コード例

#### 例1: 配送方法選択

注文金額と配送先で利用可能な方法が決まる場合。

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

#### 例2: 会員ランク（パラメータ化）

ランク追加が頻繁な場合はデータ構造として外部化。

```typescript
// BAD: 固定列挙（変更のたびにコード修正）
type MemberRank = "bronze" | "silver" | "gold";

function getDiscount(rank: MemberRank): number {
  switch (rank) {
    case "bronze": return 0.05;
    case "silver": return 0.10;
    case "gold": return 0.15;
  }
}

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

#### 例3: BMI判定（連続値の区分化）

連続値でも医学的基準により区分が存在する場合。

```typescript
// Step 1: 出力は列挙可能か？ → No（BMI自体は連続値）
// Step 2: 結果カテゴリに差異があるか？ → Yes（医学的基準で3区分）

type BmiCategory = "underweight" | "normal" | "overweight";

function categorizeBmi(bmi: number): BmiCategory {
  if (bmi < 18.5) return "underweight";
  if (bmi < 25) return "normal";
  return "overweight";
}

// 各カテゴリで後続処理が異なる
function getHealthAdvice(category: BmiCategory): string {
  switch (category) {
    case "underweight": return "栄養摂取を増やしましょう";
    case "normal": return "現状維持を心がけましょう";
    case "overweight": return "運動と食事管理を推奨します";
  }
}
```

---

### テストへの活用

定義した区分は**同値分割法の同値クラス**として直接利用できる。

```typescript
// 配送方法の例: 3(金額区分) × 3(地域区分) = 9パターン
describe("getAvailableMethods", () => {
  // 各同値クラスから代表値を選定
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

コードレビュー時に確認：

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
