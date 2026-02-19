# テストの原則

t_wada（和田卓人）氏の自動テストに関する知見をベースにした原則集。

---

## 自動テストの目的

> 信頼性の高い実行結果に短時間で到達する状態を保つことで、
> 開発者に**根拠ある自信**を与え、ソフトウェアの成長を持続可能にすること

テストの価値は「コスト削減」ではなく「変化に対応する力」を得ること。

---

## テストの信頼性：偽陽性と偽陰性

信頼できるテストとは「嘘がないテスト」。嘘には2種類ある。

### 偽陽性（False Positive）

**コードは正しいのにテストが失敗する**

```
火が出ていないのに火災報知器が鳴る状態
```

パターン:
- **Flaky Test（信頼不能テスト）**: コードに触れていないのに結果が不安定
- **Brittle Test（脆いテスト）**: 実装の詳細変更でテストが壊れる

対策:
- 実装の詳細ではなく、振る舞いをテストする
- 時間やランダム性に依存しない設計
- テストダブルの適切な使用

### 偽陰性（False Negative）

**バグがあるのにテストが成功する**

```
火が出ているのに火災報知器が鳴らない状態
```

パターン:
- カバレッジ不足
- `skip` されたまま放置されたテスト
- テストコードがプロダクトコードのバグを再現している

対策:
- テストリストで網羅性を確保
- 境界値・異常系のテストを必ず含める
- ミューテーションテストの活用

---

## テストの3品質

良いテストは3つの品質を最大化する。ただし、これらはトレードオフの関係にある。

| 品質 | 意味 | 低いとどうなる |
|------|------|---------------|
| **Fidelity（忠実性）** | バグを検出する能力 | 偽陰性（バグを見逃す） |
| **Resilience（回復力）** | リファクタで壊れない | 偽陽性（正しいのに失敗） |
| **Precision（精度）** | 失敗時に原因が明確 | デバッグに時間がかかる |

**Fidelity↑ と Resilience↑ は両立が難しい**：
- Fidelityを上げようと詳細をテスト → 実装依存で壊れやすくなる（Resilience↓）
- Resilienceを上げようと抽象的にテスト → バグを見逃しやすくなる（Fidelity↓）

**解決策**: 公開APIの振る舞いをテストし、内部実装はテストしない。

---

## テストサイズ（Small / Medium / Large）

「単体テスト」「結合テスト」は定義がブレる。代わりにサイズで分類する。

| サイズ | 制約 | 実行速度 | 信頼性 |
|--------|------|----------|--------|
| **Small** | 単一プロセス、外部アクセスなし | 最速 | 最高 |
| **Medium** | 単一マシン、ローカルDB/コンテナ可 | 中程度 | 高 |
| **Large** | 制約なし、外部システム接続可 | 遅い | 変動あり |

### 推奨される配置

```
ドメインロジック    → Small × 単体
Controller/Service → Small × 統合（テストダブル使用）
Repository         → Medium × 単体（Fake DB使用）
E2E               → Large（最小限に）
```

### テストピラミッド

```
        /\
       /  \  Large（少）
      /----\
     /      \  Medium
    /--------\
   /          \  Small（多）
  --------------
```

逆三角形（アイスクリームコーン）は避ける。E2Eが多すぎると遅く不安定になる。

### テストレベル間の重複回避

同じシナリオを複数レベルでテストしない。各テストが「このレベルでしか検証できないこと」に焦点を当てる。

---

## テストダブルの役割

テストダブルの最重要目的は**テストサイズを下げること**。

| 種類 | 用途 |
|------|------|
| **Fake** | 本物の簡易版（DynamoDB Local、LocalStack等） |
| **Stub** | 固定値を返す |
| **Mock** | 呼び出しを検証（使いすぎ注意） |

### Fakeでサイズを下げる

```
Large（本番DB）→ Medium（Fake DB）→ Small（インメモリ）
```

Dockerを使うとSmallからMediumに上がる。数が増えると実行時間が掛け算で増える。

### Mockの注意点

Mockを多用すると:
- 実装の詳細に依存（Brittle Test化）
- 自己検証的なテストになりやすい

振る舞いの検証にはFakeを優先する。

### 状態テスト vs インタラクションテスト

| 種類 | 検証対象 | 例 |
|------|---------|-----|
| **状態テスト** | 結果が正しいか | `expect(sort([3,1,2])).toEqual([1,2,3])` |
| **インタラクションテスト** | 正しいメソッドを呼んだか | `expect(mockSort).toHaveBeenCalledWith([3,1,2])` |

**原則: 状態テストを優先する**

インタラクションテストは「メソッドを呼んだ」ことしか保証しない。呼んだメソッドが正しく動くかは保証されない。

**インタラクションテストが適切な場面**: 副作用の検証（メール送信等）、外部APIの呼び出し回数制限、パフォーマンス検証。

### Change-Detector Tests（変更検出テスト）

**最悪のBrittle Test**：実装をそのままテストに写しただけのテスト。

```typescript
// BAD: Change-Detector Test（実装の鏡）
it('processOrderを呼ぶ', () => {
  const spy = jest.spyOn(service, 'validate');
  const spy2 = jest.spyOn(service, 'save');
  const spy3 = jest.spyOn(service, 'notify');

  service.processOrder(order);

  expect(spy).toHaveBeenCalledBefore(spy2);
  expect(spy2).toHaveBeenCalledBefore(spy3);
});
// → 実装の順序を変えただけで壊れる。振る舞いは変わっていないのに。

// GOOD: 振る舞いをテスト
it('注文処理後に確認メールが送信される', () => {
  service.processOrder(order);

  expect(mailService.lastSentTo).toBe(order.email);
  expect(mailService.lastSubject).toContain('ご注文確認');
});
```

**判定基準**: リファクタリングしたときにテストが壊れるなら、それは振る舞いではなく実装をテストしている。

---

## 良いテストの書き方

### テストコードは「愚直に」書く（DAMP > DRY）

テストコードは**可読性と意図の明確さ**を最優先する。

| 本番コード | テストコード |
|-----------|------------|
| DRY（重複排除） | DAMP（意図が明確な適度な重複） |
| 抽象化・共通化推奨 | ハードコード・ベタ書き推奨 |
| ヘルパー関数で整理 | 各テストが自己完結 |

**テストコードに入れてはいけないもの**: `if` / `for` / `while` 等の制御構文。テストにロジックが入ると、テスト自体にバグが生まれる。

### AAA パターン

```
Arrange（準備）→ Act（実行）→ Assert（検証）
```

各セクションを明確に分離する。

### テスト名は振る舞いを記述

```typescript
// BAD: 実装の詳細
it('setStateが呼ばれる')

// GOOD: 振る舞い
it('ログインボタンをクリックするとダッシュボードに遷移する')
```

### 1テスト1アサーション（原則）

複数のアサーションがあると、最初の失敗で止まり、全体像が見えない。

### テーブルドリブンテスト（`it.each` / `test.each`）

同じロジックを複数の入力パターンで検証する場合、テーブル形式で簡潔に記述する。

```typescript
it.each([
  { input: '',          expected: '必須です' },
  { input: 'a@',        expected: '形式が不正です' },
  { input: 'a@b.com',   expected: undefined },
])('メール "$input" → エラー: $expected', ({ input, expected }) => {
  expect(validateEmail(input).error).toBe(expected);
});
```

**使い分け**: 入力→出力の網羅的検証にはテーブル形式、ユーザー操作を含む振る舞いテストには個別テストが読みやすい。

### 性質ベースのアサーション（kawasima）

期待する結果を「データの完全一致」ではなく「満たすべき性質」で検証する。

```typescript
// BAD: セットアップデータとの完全一致（マッチポンプテスト）
const hoge = new User(1, "hoge-san", 3);
const users = userDao.findByPartialName("hoge");
expect(users).toContain(hoge);  // セットアップデータをそのまま検証

// GOOD: 戻り値が満たすべき性質を検証
const users = userDao.findByPartialName("hoge");
expect(users.length).toBeGreaterThan(0);
expect(users.every(u => u.name.includes("hoge"))).toBe(true);
```

マッチポンプテストはセットアップ変更に弱く仕様が読み取れない。性質ベースアサーションはテストが仕様書として機能し、Resilience↑ と Fidelity↑ を両立する。

### テストデータは業務上の前提を反映する

テストデータは技術的に有効なだけでなく、**業務ロジック上も現実的**であるべき。

```typescript
// BAD: 技術的には動くが、業務上ありえないデータ
// 「修正版」があるのに「オリジナル」がない
const testData = [
  { type: 'revision_v2', content: '...' },
];

// GOOD: 業務上の前提を反映
// 「修正版」があるなら「オリジナル」も存在する
const testData = [
  { type: 'original', content: '...' },
  { type: 'revision_v2', content: '...' },
];
```

**考慮すべき業務上の前提**: 派生データ→元データの存在、状態遷移の順序、親子関係、時系列の整合性。

#### 時間フィルタ付きクエリの注意

`WHERE timestamp >= Date.now() - N日` のようなクエリをテストする場合、固定の過去日付はフィルタ範囲外になりうる。

```typescript
// ❌ BAD: 固定日付は時間経過でフィルタ範囲外になる
const timestampMs = new Date("2025-01-15T12:00:00Z").getTime();

// ✅ GOOD: Date.now() 基準の相対日付で常にフィルタ範囲内
const timestampMs = Date.now() - 2 * 24 * 60 * 60 * 1000; // 2日前
```

---

## テスト実装の手順

### 1. テスト観点表を先に作る

テストコードを書く前に、Markdown形式のテスト観点表を作成する。

| Case ID | Input / Precondition | Perspective | Expected Result | Notes |
|---------|---------------------|-------------|-----------------|-------|
| TC-N-01 | 有効な入力A | 等価分割 - 正常系 | 処理成功、期待値を返す | - |
| TC-A-01 | NULL | 境界値 - NULL | バリデーションエラー | - |
| TC-A-02 | 空文字 | 境界値 - 空 | バリデーションエラー | - |
| TC-B-01 | 最小値-1 | 境界値 - 下限外 | 範囲エラー | - |
| TC-B-02 | 最小値 | 境界値 - 下限 | 処理成功 | - |
| TC-B-03 | 最大値 | 境界値 - 上限 | 処理成功 | - |
| TC-B-04 | 最大値+1 | 境界値 - 上限外 | 範囲エラー | - |

**境界値チェックリスト**: `0 / 最小値 / 最大値 / ±1 / 空 / NULL`

### 2. 正常系と同数以上の失敗系

正常系だけでは偽陰性（バグを見逃す）リスクが高い。`正常系 : 失敗系 = 1 : 1以上`

失敗系に含めるもの: バリデーションエラー、例外パス、不正な型・形式の入力、外部依存の失敗（API / DB）。

### 3. Given / When / Then コメント

各テストケースに `// Given: ... // When: ... // Then: ...` コメントを付与し、シナリオを追えるようにする。

### 4. 例外・エラーの検証

例外が発生するケースでは、**型とメッセージ**を明示的に検証する。

```typescript
// BAD: 例外が投げられることだけ確認
expect(() => fn()).toThrow();

// GOOD: 例外の型とメッセージを検証
expect(() => fn()).toThrow(ValidationError);
expect(() => fn()).toThrow('Email is required');
```

### 5. カバレッジ目標

- **全体80%以上**を目標とする
- 新規コードは **90%以上** を目指す
- クリティカルパス（認証、決済等）は **100%**
- 未カバーの分岐がある場合は、理由をPR本文に明記

---

## リスクベースのテスト戦略

> テストは目的のための手段である。
> 目的は「プロジェクトの主要リスクを減らすこと」であり、「慣習に従うこと」ではない。

### 推奨アプローチ: Risks First

1. プロジェクトの主要リスクを特定する
2. 各リスクに対する緩和策を検討する
3. テストはリスク緩和の手段の一つとして位置づける
4. **ROI（投資対効果）を意識する**

短期間で廃止される機能など、テストを書かない判断もありうる。ただし、ほとんどの場合は標準的なテスト戦略が有効。

---

## レガシーコードへのテスト追加

テストなしのコードを改善する際の戦略（t_wada）。

> テストがないと安全にコードを変更できない。
> しかしテストを書くにはコードを変更する必要がある。

### 解決アプローチ

1. **リクエスト/レスポンスレベルから始める** — 実装から距離を取り、入力と出力の関係を簡潔にテスト
2. **Seam（継ぎ目）を見つける** — 依存性を外部から注入可能にする

```typescript
// BAD: ランダム性が内部に閉じている
function generateId() {
  return Math.random().toString(36);
}

// GOOD: ランダム性を注入可能に
function generateId(randomFn = Math.random) {
  return randomFn().toString(36);
}
```

3. **Extract 戦略** — 既存コードにテストを書き現状を記録 → 段階的に抽出 → 変更理由が同じものをまとめ、異なるものを分離
4. **ドメインとインフラの分離** — ドメイン層（テスト容易）をインフラ層（HTTP/Lambda/外部API）から分離し、ドメインを TDD で育てる

---

フロントエンド固有のテスト手法は @~/.claude/rules/web-frontend.md（フロントエンドテストセクション）を参照。

---

## 参考資料

- [kawasima - Writing effective tests](https://scrapbox.io/kawasima/Writing_effective_tests)
- [t_wada - 組織に自動テストを書く文化を根付かせる戦略](https://speakerdeck.com/twada/building-automated-test-culture-2024-winter-edition)
- [t_wada - 開発生産性の観点から考える自動テスト](https://speakerdeck.com/twada/automated-test-knowledge-from-savanna-202406-findy-dev-prod-con-edition)
- [t_wada - レガシーコード改善の実録](https://speakerdeck.com/twada/working-with-legacy-code-the-true-record)
- [TDDは「開発者テストのTips集」](https://levtech.jp/media/article/interview/detail_477/)
- [自動テストの「嘘」をなくす方法](https://levtech.jp/media/article/column/detail_496/)
- [Google Testing Blog - Effective Testing](https://testing.googleblog.com/2014/05/testing-on-toilet-effective-testing.html)
- [Google Testing Blog - Testing State vs. Testing Interactions](https://testing.googleblog.com/2013/03/testing-on-toilet-testing-state-vs.html)
- [Google Testing Blog - Risk-Driven Testing](https://testing.googleblog.com/2014/05/testing-on-toilet-risk-driven-testing.html)
- [Google Testing Blog - Change-Detector Tests Considered Harmful](https://testing.googleblog.com/2015/01/testing-on-toilet-change-detector-tests.html)
