---
alwaysApply: true
---

# 堅牢なコードの設計原則

t_wada（和田卓人）氏の「堅牢なコードを育てる」知見をベースにした原則集。
原則は言語共通。コード例は TypeScript だが、他言語にも各言語のイディオムで適用すること。

---

## 核心思想

> 堅牢なコードとは、悪いコードに防御措置を加えるのではなく、
> **そもそも誤りにくい設計**を通じて、エラー条件自体が発生しない状況を作ること

防御的プログラミング（バリデーション追加）より、**予防的設計**を優先する。

---

## 型による予防的設計

### 1. プリミティブ型を避ける

```typescript
// BAD: string は何でも入る
function processUser(userId: string, email: string, status: string) {}

// GOOD: 専用の型で制約
function processUser(userId: UserId, email: Email, status: UserStatus) {}
```

### 2. 列挙型（Enum）の活用

```typescript
// BAD: 文字列で状態を表現
type Status = string; // "active", "inactive", "pending"...

// GOOD: 列挙型で制約
type Status = "active" | "inactive" | "pending";
// または
enum Status {
  Active = "active",
  Inactive = "inactive",
  Pending = "pending",
}
```

受け取れる値の組み合わせを劇的に削減する。

### 3. 型のモデリング

ドメイン知識を型で表現し、間違った使い方を困難にする：

```typescript
// BAD: 金額が負になる可能性
function withdraw(amount: number) {}

// GOOD: 正の数のみを型で保証
type PositiveNumber = number & { readonly brand: unique symbol };
function withdraw(amount: PositiveNumber) {}
```

---

## Parse, don't Validate

検証（validate）ではなくパース（parse）する。入力を検証しつつ、検証済みの値をより具体的な型に変換して返す。

### バリデーション（従来）

```typescript
function processEmail(input: string) {
  if (!isValidEmail(input)) {
    throw new Error("Invalid email");
  }
  // ここでは input はまだ string 型
  // 後続の処理でも検証が必要かもしれない
}
```

### パース（推奨）

```typescript
function parseEmail(input: string): Email | null {
  if (!isValidEmail(input)) {
    return null;
  }
  return input as Email; // 検証済みを型で表現
}

function processEmail(email: Email) {
  // Email 型なので検証済みが保証されている
}
```

**境界でパースし、内部では型安全に処理する。**

---

## 不変性（Immutability）

### 別名参照（Aliasing）問題

```typescript
// BAD: 参照を共有すると予期しない変更が起きる
const config = { timeout: 1000 };
const copy = config;
copy.timeout = 5000; // config も変わる！
```

### 解決策

```typescript
// GOOD: readonly で変更を防ぐ
type Config = Readonly<{
  timeout: number;
}>;

// GOOD: 新しいオブジェクトを作る
const newConfig = { ...config, timeout: 5000 };
```

### 日付の不変性

```typescript
// BAD: Date は可変
const date = new Date();
date.setMonth(date.getMonth() + 1); // 元のオブジェクトが変わる

// GOOD: 新しいインスタンスを作る（ライブラリ使用推奨）
import { addMonths } from "date-fns";
const nextMonth = addMonths(date, 1);
```

---

## 完全性（Integrity）

### 不変条件をコンストラクタで保証

```typescript
class DateRange {
  constructor(
    readonly start: Date,
    readonly end: Date
  ) {
    // 不変条件: start <= end
    if (start > end) {
      throw new Error("Start must be before or equal to end");
    }
  }
}

// 生成された DateRange は常に有効
// 不正な状態のインスタンスは存在できない
```

### ファクトリメソッドパターン

```typescript
class User {
  private constructor(
    readonly id: UserId,
    readonly email: Email
  ) {}

  static create(id: string, email: string): User | null {
    const parsedId = parseUserId(id);
    const parsedEmail = parseEmail(email);
    if (!parsedId || !parsedEmail) {
      return null;
    }
    return new User(parsedId, parsedEmail);
  }
}
```

---

## 責務の配置

### 事実と情報の分離

```typescript
// 事実（Fact）: タイムスタンプ付きの生データ
interface OrderPlaced {
  orderId: string;
  items: Item[];
  placedAt: Date;
}

// 情報（Information）: 事実から計算で導出
function calculateTotal(order: OrderPlaced): Money {
  return order.items.reduce((sum, item) => add(sum, item.price), Money.zero());
}
```

- **事実**: 不変、保存する
- **情報**: 事実から計算で導出、キャッシュは可

### 変更のタイミングと理由

> 変更のタイミングと理由が同じものはまとめる。
> 異なるものは分離する。

```typescript
// BAD: 異なる理由で変更されるものが混在
class UserService {
  validateEmail() {} // バリデーションルール変更
  sendWelcomeEmail() {} // メール文面変更
  saveToDatabase() {} // スキーマ変更
}

// GOOD: 責務で分離
class EmailValidator {}
class WelcomeMailer {}
class UserRepository {}
```

---

## チェックリスト

コードレビュー時に確認：

- [ ] プリミティブ型ではなく、意味のある型を使っているか
- [ ] 不正な状態を型レベルで排除しているか
- [ ] オブジェクトの不変条件はコンストラクタで保証されているか
- [ ] 可変性が必要な理由を説明できるか
- [ ] 境界（入力）でパースし、内部は型安全か
- [ ] 事実と情報（計算結果）は分離されているか
- [ ] 実行前に検出できるエラーは静的解析で検出しているか（strict mode、lint）

---

## 参考資料

- [t_wada - 堅牢なコードを育てるための設計ヒント](https://speakerdeck.com/twada/growing-reliable-code-php-conference-fukuoka-2025)
