---
globs: ["*.ts", "*.tsx"]
---

# TypeScript 言語規約

`robust-code.md` の設計原則を TypeScript で実現するための具体的パターン集。
パッケージ管理は `javascript.md` を参照。

---

## 1. プリミティブ型を避ける → Branded Type（unique symbol）

参考: [uhyo氏の解説](https://qiita.com/uhyo/items/de4cb2085fdbdf484b83)

```typescript
// --- userId.ts ---
const userIdBrand = Symbol();
export type UserId = string & { [userIdBrand]: unknown };

export function createUserId(rawId: string): UserId {
  return rawId as UserId;
}
```

- シンボルは **export しない**（型の嘘をモジュール内に閉じ込める）
- 型の生成は **ファクトリ関数経由** に限定する
- 文字列キー `{ __brand__: "..." }` は補完汚染・型安全性の穴があるため使わない

---

## 2. 列挙型の活用 → Discriminated Union + 網羅性チェック

参考: [サバイバルTypeScript](https://typescriptbook.jp/reference/values-types-variables/discriminated-union) / [一休の Discriminated Union 活用](https://user-first.ikyu.co.jp/entry/2024/12/13/152224)

### 不可能な状態を型で排除する

Discriminated Union の本質は**存在しない状態を型に含めない**こと。
プロパティをオプショナルにするのではなく、状態ごとに型を分ける：

```typescript
// BAD: 不可能な組み合わせが表現できてしまう（loaded なのに data が undefined）
type State = {
  status: "loading" | "loaded" | "error";
  data?: Data;
  error?: Error;
};

// GOOD: 各状態が持つプロパティを厳密に定義
type State =
  | { status: "loading" }
  | { status: "loaded"; data: Data }
  | { status: "error"; error: Error };
```

### 網羅性チェック（assertNever）

```typescript
function assertNever(x: never): never {
  throw new Error(`Unexpected value: ${x}`);
}

function render(state: State) {
  switch (state.status) {
    case "loading":
      return <Spinner />;
    case "loaded":
      return <Content data={state.data} />;
    case "error":
      return <ErrorView error={state.error} />;
    default:
      assertNever(state); // 新バリアント追加時にコンパイルエラー
  }
}
```

### コンパニオンオブジェクトパターン

型と同名の関数をファクトリとして定義する（robust-code のファクトリメソッドの TS イディオム）：

```typescript
type Icon = EmojiIcon | UrlIcon | NoIcon;

interface EmojiIcon { kind: "emoji"; symbol: string }
interface UrlIcon   { kind: "url";   src: string }
interface NoIcon    { kind: "none" }

// 型と同名の関数 → 生成ロジックをカプセル化
function EmojiIcon(symbol: string): EmojiIcon {
  return { kind: "emoji", symbol };
}
function UrlIcon(src: string): UrlIcon {
  return { kind: "url", src };
}
function NoIcon(): NoIcon {
  return { kind: "none" };
}

// 使う側：new なしで直感的に生成
const icon = EmojiIcon("🎉");
```

### その他のプラクティス

- `enum` より **union 型 + リテラル判別** を優先する（tree-shaking 可能、型推論が効く）
- `satisfies` で定数オブジェクトの型安全性を確保する：

```typescript
const STATUS_LABELS = {
  active: "有効",
  inactive: "無効",
  pending: "保留中",
} as const satisfies Record<Status, string>;
```

---

## 3. Parse, don't Validate → 型述語・assertion function

### 型述語（Type Predicate）

```typescript
function isEmail(input: string): input is Email {
  return /^[^@]+@[^@]+\.[^@]+$/.test(input);
}

// 使う側：型が絞り込まれる
if (isEmail(input)) {
  sendMail(input); // input: Email
}
```

### パースファクトリ（推奨）

```typescript
function parseEmail(input: string): Email | null {
  if (!isEmail(input)) return null;
  return input; // isEmail の型述語により Email 型
}

// 境界でパースし、内部は Email 型で安全に処理
const email = parseEmail(rawInput);
if (!email) throw new InvalidInputError("email");
processEmail(email); // Email 型が保証済み
```

### assertion function（前提条件の表明）

```typescript
function assertNonNull<T>(value: T | null | undefined, msg?: string): asserts value is T {
  if (value == null) throw new Error(msg ?? "Unexpected null");
}

// 呼び出し後、型が絞り込まれる
assertNonNull(user);
user.name; // user: User（null | undefined が除外）
```

---

## 4. 不変性 → as const・Readonly・readonly

```typescript
// as const: リテラル型を保持する
const ROLES = ["admin", "editor", "viewer"] as const;
type Role = (typeof ROLES)[number]; // "admin" | "editor" | "viewer"

// Readonly<T>: オブジェクト全体を不変に
type Config = Readonly<{
  timeout: number;
  retries: number;
}>;

// ReadonlyArray<T>: 配列の変更を防ぐ
function process(items: readonly Item[]) {
  // items.push(...) → コンパイルエラー
}

// 関数引数には readonly を付ける（意図しない変更を防ぐ）
function sum(values: readonly number[]): number {
  return values.reduce((a, b) => a + b, 0);
}
```

---

## 5. 完全性 → private constructor + ファクトリ

```typescript
class DateRange {
  private constructor(
    readonly start: Date,
    readonly end: Date
  ) {}

  static create(start: Date, end: Date): DateRange | null {
    if (start > end) return null;  // 不変条件: start <= end
    return new DateRange(start, end);
  }

  // 不変条件を維持した操作のみ公開
  extend(newEnd: Date): DateRange | null {
    return DateRange.create(this.start, newEnd);
  }
}
```

- `private constructor` で直接 new を禁止し、ファクトリ経由のみで生成する
- 不変条件に違反する入力は `null` を返す（Parse, don't Validate と組み合わせる）
- 公開メソッドも不変条件を維持するようファクトリを再利用する
