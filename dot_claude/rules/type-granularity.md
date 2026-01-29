# 型の粒度設計

kawasima氏の知見に基づく、振る舞いの境界を型として明示する設計手法。

関連: @~/.claude/rules/robust-code.md（型による予防的設計）

---

## 核心思想

> 「区分」とは業務の区分値コードではなく、
> **型システムにおける直和型（OR）の各選択肢**である。

代数的データ型のバリアントに相当する概念。

---

## 4段階の判断フロー

型の粒度を決定する際の判断プロセス。

### Step 1: 出力は列挙可能か？

仕様で有限個の選択肢として明示されているか確認する。

- 表、固定文言、直和型での列挙形式を検出
- **Yes** → Step 3へ
- **No** → Step 2へ

### Step 2: 結果カテゴリに差異があるか？

以下のいずれかが異なるか確認する：

- **不変条件**: カテゴリごとに成り立つべき制約
- **後続処理**: カテゴリによって処理が分岐
- **境界値**: カテゴリを分ける閾値

**Yes（いずれかが異なる）** → 区分を作成
**No（すべて同じ）** → 区分化は不要

### Step 3: 型定義方法の選択

| パターン | 説明 | 使用場面 |
|----------|------|----------|
| **A: 入力をORで区分** | 各ケースで異なる処理 | 分岐ロジックが複雑 |
| **B: 中間の区分型を導入** | 全ケースで同じ処理 | 結果の種類を表現 |

### Step 4: 固定列挙 vs パラメータ化

| 固定列挙 | パラメータ化 |
|----------|--------------|
| 有限・確定 | 多数・頻繁な変更 |
| 変更頻度が低い | 均質な処理 |
| コードで定義 | データで定義 |

---

## コード例

### 例1: 配送方法選択

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

### 例2: 会員ランク（パラメータ化）

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

### 例3: BMI判定（連続値の区分化）

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

## テストへの活用

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

- [ ] 出力の列挙可能性を確認したか
- [ ] 結果カテゴリごとの差異（不変条件、後続処理、境界値）を検証したか
- [ ] 入力のOR区分と中間区分型を適切に選択したか
- [ ] 固定列挙とパラメータ化を適切に選択したか
- [ ] 区分を同値クラスとしてテストに活用したか

---

## 参考資料

- [kawasima - 型の粒度設計](https://scrapbox.io/kawasima/%E5%9E%8B%E3%81%AE%E7%B2%92%E5%BA%A6%E8%A8%AD%E8%A8%88)
