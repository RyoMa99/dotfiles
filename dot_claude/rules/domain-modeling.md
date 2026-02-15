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

## チェックリスト

コードレビュー時に確認：

- [ ] 仕様表の背後に隠れた意図（WHY）を発見したか
- [ ] 仕様の軸が直交しているか（変更が他の軸に波及しないか）
- [ ] フラグをORに置き換えられないか
- [ ] ステータスコードを型と遷移で表現できないか
- [ ] 条件判定（マジックナンバー）に名前を付けたか
- [ ] 「ほぼ同じdata」を適切に整理したか
- [ ] 不変条件を型で強制しているか
- [ ] 振る舞いの失敗ケースをORで明示したか
- [ ] ORとListを適切に使い分けているか

---

## 参考資料

- [kawasima - ドメイン記述ミニ言語](https://scrapbox.io/kawasima/%E3%83%89%E3%83%A1%E3%82%A4%E3%83%B3%E8%A8%98%E8%BF%B0%E3%83%9F%E3%83%8B%E8%A8%80%E8%AA%9E)
- [Domain Modeling Made Functional](https://pragprog.com/titles/swdddf/domain-modeling-made-functional/)
- [広木大地 - スケールする要求を支える仕様の「意図」と「直交性」](https://qiita.com/hirokidaichi/items/61ad129eae43771d0fc3)
