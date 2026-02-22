---
globs: ["*.ts", "*.tsx"]
---

# TypeScript 言語規約

`robust-code.md` の設計原則を TypeScript で適用する際の、プロジェクト固有の選択。
パッケージ管理は `javascript.md` を参照。

---

## Branded Type は unique symbol 方式

IMPORTANT: 文字列キー `{ __brand__: "..." }` は使わない（補完汚染・型安全性の穴）。

```typescript
const userIdBrand = Symbol();
export type UserId = string & { [userIdBrand]: unknown };
export function createUserId(rawId: string): UserId {
  return rawId as UserId;
}
```

- シンボルは **export しない**（型の嘘をモジュール内に閉じ込める）
- 型の生成は **ファクトリ関数経由** に限定する

---

## Discriminated Union

- `enum` より **union 型 + リテラル判別** を優先する（tree-shaking 可能、型推論が効く）
- 不可能な状態をオプショナルプロパティで表現せず、状態ごとに型を分ける
- `satisfies` で定数オブジェクトの型安全性を確保する
- コンパニオンオブジェクトパターン: 型と同名の関数をファクトリとして定義する

```typescript
type Icon = EmojiIcon | UrlIcon;
interface EmojiIcon { kind: "emoji"; symbol: string }
function EmojiIcon(symbol: string): EmojiIcon { return { kind: "emoji", symbol }; }
```

---

## assertion function を使う

IMPORTANT: 前提条件の表明には assertion function（`asserts value is T`）を使う。
if ガードで早期 return するより assertion function を優先する。型の絞り込みが後続コードに伝播し、呼び出し元の型安全性が向上する。

```typescript
function assertNonNull<T>(value: T | null | undefined, msg?: string): asserts value is T {
  if (value == null) throw new Error(msg ?? "Unexpected null");
}

assertNonNull(user);
user.name; // user: User（null | undefined が除外）
```

---

## 関数引数には readonly を付ける

配列・オブジェクト引数には `readonly` を付け、意図しない変更を防ぐ。
