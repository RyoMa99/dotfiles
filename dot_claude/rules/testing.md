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

インタラクションテストは「メソッドを呼んだ」ことしか保証しない。
呼んだメソッドが正しく動くかは保証されない。

**インタラクションテストが適切な場面**:
- 副作用の検証（メール送信、ログ出力など）
- 外部APIの呼び出し回数制限
- パフォーマンス・スレッド処理の検証

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

### テストコードも本番コードと同じ品質で

テストコードだから簡易的に書いてよい、ではない。
メンテナンスし続けるコードとして質を追求する。

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

**マッチポンプテストの問題点**:
1. スキーマやセットアップデータ変更時に、期待値もメンテナンスが必要
2. テストコードから仕様が読み取れない
3. 実質的にデータストアのテストであり、ビジネスロジックの検証になっていない

**性質ベースアサーションの利点**:
- テストが仕様書として機能する（「hogeを含む名前のユーザーを返す」）
- セットアップデータの変更に強い（Resilience↑）
- バグ検出能力が高い（Fidelity↑）

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

**考慮すべき業務上の前提**:
- 派生データがあるなら元データも存在する
- 状態遷移の順序（下書き → 公開 → アーカイブ）
- 親子関係（親なしの子は存在しない）
- 時系列の整合性（作成日 < 更新日）

現実にありえないテストデータは、テストの信頼性（Fidelity）を下げる。

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

正常系だけでは偽陰性（バグを見逃す）リスクが高い。

```
正常系 : 失敗系 = 1 : 1以上
```

失敗系に含めるもの:
- バリデーションエラー
- 例外パス
- 不正な型・形式の入力
- 外部依存の失敗（API / DB）

### 3. Given / When / Then コメント

各テストケースにコメントを付与し、シナリオを追えるようにする。

```typescript
it('無効なメールアドレスでバリデーションエラーになる', () => {
  // Given: 不正な形式のメールアドレス
  const invalidEmail = 'not-an-email';

  // When: バリデーションを実行
  const result = validateEmail(invalidEmail);

  // Then: エラーが返される
  expect(result.isValid).toBe(false);
  expect(result.error).toBe('Invalid email format');
});
```

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

### アンチパターン

あるチームは unit / integration / UI テストを網羅的に書いたが、
実際のリスク（データ破損、サーバーダウン）はテストされておらず、リリース直前に問題が発覚した。

### 推奨アプローチ: Risks First

1. プロジェクトの主要リスクを特定する
2. 各リスクに対する緩和策を検討する
3. テストはリスク緩和の手段の一つとして位置づける
4. **ROI（投資対効果）を意識する**

### テストを書かない判断もありうる

- 短期間で廃止される機能 → 手動テストの方が費用対効果が高い場合も
- ただし、ほとんどの場合は標準的なテスト戦略が有効

---

## レガシーコードへのテスト追加

テストなしのコードを改善する際の戦略（t_wada）。

### ジレンマ

> テストがないと安全にコードを変更できない。
> しかしテストを書くにはコードを変更する必要がある。

### 解決アプローチ

#### 1. リクエスト/レスポンスレベルから始める

```
実装から距離を取りつつ、安定したテストを書ける
```

- 最初は完全一致を求めず、簡潔なアサーションから開始
- 入力と出力の関係をテストする（実装詳細に依存しない）

#### 2. Seam（継ぎ目）を見つける

依存性を外部から注入可能にして、テスト駆動で開発できる環境を整備：

```typescript
// BAD: ランダム性が内部に閉じている
function generateId() {
  return Math.random().toString(36);
}

// GOOD: ランダム性を注入可能に
function generateId(randomFn = Math.random) {
  return randomFn().toString(36);
}

// テスト時
generateId(() => 0.5); // 決定的な結果
```

#### 3. Extract戦略

既存コードを壊さずに、テスト可能なコードを抽出：

```
1. 既存コードにテストを書く（現状の動作を記録）
2. 新しいコードを段階的に抽出
3. 変更のタイミング・理由が同じものをまとめる
4. 異なるものは分離する
```

### ドメインとインフラの分離

```
┌─────────────────────────────────────┐
│  インフラ層（テスト困難）           │
│  - HTTP/Lambda/外部API              │
└─────────────────────────────────────┘
              ↓ 依存
┌─────────────────────────────────────┐
│  ドメイン層（テスト容易）           │
│  - ビジネスロジック                 │
│  - TDDで段階的に成長                │
└─────────────────────────────────────┘
```

ドメインをインフラから分離し、ドメインをテスト駆動で育てる。

---

## フロントエンドテスト

バックエンドのテストピラミッドとは異なり、フロントエンドでは**テストトロフィー**モデルを採用する。

関連: @~/.claude/rules/web-frontend.md

### テストトロフィー

```
        /\
       /  \  E2E（少）
      /----\
     /      \  Integration（最多）← フロントエンドの主戦場
    /--------\
   /          \  Unit（中）
  --------------
  Static（型チェック・lint）
```

**バックエンドのテストピラミッドとの違い**:
- バックエンド: Unit テストが最多（ドメインロジック中心）
- フロントエンド: Integration テストが最多（コンポーネント結合の振る舞い中心）

### Integration テスト = コンポーネントテスト

フロントエンドの Integration テストは、複数のコンポーネントが結合した状態でユーザー操作をシミュレートするテスト。

#### Testing Library のユーザー視点アプローチ

```typescript
// BAD: 実装の詳細をテスト
it('setStateが呼ばれる', () => {
  const wrapper = shallow(<LoginForm />);
  wrapper.find('input').simulate('change', { target: { value: 'user@example.com' } });
  expect(wrapper.state('email')).toBe('user@example.com');
});

// GOOD: ユーザーの視点でテスト（Testing Library）
it('メールアドレスを入力してログインできる', async () => {
  const user = userEvent.setup();
  render(<LoginForm onSubmit={mockSubmit} />);

  await user.type(screen.getByLabelText('メールアドレス'), 'user@example.com');
  await user.type(screen.getByLabelText('パスワード'), 'password123');
  await user.click(screen.getByRole('button', { name: 'ログイン' }));

  expect(mockSubmit).toHaveBeenCalledWith({
    email: 'user@example.com',
    password: 'password123',
  });
});
```

#### クエリの優先順位

Testing Library のクエリは以下の優先順位で選択する（アクセシビリティに基づく）：

| 優先度 | クエリ | 用途 |
|--------|--------|------|
| 1（推奨） | `getByRole` | ボタン、リンク、フォーム要素 |
| 2 | `getByLabelText` | フォームフィールド |
| 3 | `getByPlaceholderText` | label がない場合のフォールバック |
| 4 | `getByText` | テキスト表示要素 |
| 5（最終手段） | `getByTestId` | 他のクエリで特定できない場合のみ |

```typescript
// BAD: data-testid への依存
screen.getByTestId('submit-button');

// GOOD: ロールで取得（スクリーンリーダーと同じアクセス方法）
screen.getByRole('button', { name: '送信' });
```

### アクセシビリティテスト

#### axe-core 統合

自動テストに axe-core を組み込み、a11y 違反を検出する。

```typescript
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

it('アクセシビリティ違反がない', async () => {
  const { container } = render(<OrderForm />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

#### a11y テストで検出できるもの

- label の欠落
- コントラスト比不足
- aria 属性の不正使用
- 見出しレベルのスキップ
- 画像の alt テキスト欠落

#### a11y テストで検出できないもの

- キーボード操作の実際の使い勝手
- スクリーンリーダーでの読み上げ順序の妥当性
- 認知的負荷の高さ

→ 自動テストは**最低限の品質担保**。手動テストも併用する。

### フロントエンドテスト観点マトリクス

| テスト対象 | テスト種類 | ツール | 確認内容 |
|-----------|-----------|--------|---------|
| ユーティリティ関数 | Unit | Vitest / Jest | 入出力の正しさ |
| カスタム hooks | Unit | renderHook | 状態遷移、副作用 |
| 単一コンポーネント | Integration | Testing Library | 表示・操作・a11y |
| フォーム | Integration | Testing Library | バリデーション・送信・エラー表示 |
| ページ（複数コンポーネント結合） | Integration | Testing Library + MSW | データ取得・表示・操作の統合 |
| ユーザーフロー | E2E | Playwright / Cypress | 画面遷移を含む一連の操作 |
| ビジュアル | Visual Regression | Storycap + reg-suit | UIの意図しない変更検出 |

### MSW（Mock Service Worker）の活用

API モックは MSW で統一し、テストとローカル開発で共有する。

```typescript
// handlers.ts: API モックの定義
export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: 1, name: 'Alice' },
      { id: 2, name: 'Bob' },
    ]);
  }),

  http.post('/api/orders', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: 1, ...body }, { status: 201 });
  }),
];

// テストで使用
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

it('ユーザー一覧を表示する', async () => {
  render(<UserList />);
  expect(await screen.findByText('Alice')).toBeInTheDocument();
  expect(screen.getByText('Bob')).toBeInTheDocument();
});

// エラーケースのテスト
it('API エラー時にエラーメッセージを表示する', async () => {
  server.use(
    http.get('/api/users', () => {
      return HttpResponse.json({ message: 'Internal Server Error' }, { status: 500 });
    }),
  );

  render(<UserList />);
  expect(await screen.findByRole('alert')).toHaveTextContent('データの取得に失敗しました');
});
```

### ビジュアルリグレッションテスト（VRT）

CSSの変更は意図しないUI崩れを引き起こしやすいが、ロジックテストでは検出できない。
VRTはスクリーンショットの差分比較で視覚的な変更を検出する。

#### なぜ必要か

```
Unit / Integration テストで保証できること → ロジック・振る舞い
VRT で保証できること → レンダリング結果（ピクセル単位）
```

例: ボタンの背景色が白に変わっても、テストは `getByRole('button')` で取得できるため通る。
VRTなら「見た目が変わった」ことを画像差分で検出できる。

#### ローカル実行ワークフロー: Storycap + reg-suit

```bash
# 1. Storybookの全ストーリーをスクリーンショット化
npx storycap http://localhost:6006 --outDir ./screenshots/actual

# 2. 画像差分を比較（初回はベースラインを作成）
npx reg-suit compare

# 3. 差分レポートをブラウザで確認
open ./reg-suit-report/index.html
```

**Storycap**: Storybook上の各ストーリーを自動でキャプチャ。`waitFor` や `delay` オプションで非同期コンテンツの描画完了を待てる。

**reg-suit**: 2つのスクリーンショットディレクトリを比較し、差分をHTMLレポートで可視化。閾値を設定して微小な差分（アンチエイリアス等）を無視できる。

#### VRT対象の選定

すべてのストーリーを撮るのではなく、効果の高い対象に絞る：

| 対象 | 理由 |
|------|------|
| 共通UIコンポーネント（Button, Input, Card等） | 変更の影響範囲が広い |
| レイアウトコンポーネント（Header, Sidebar等） | 位置関係の崩れを検出 |
| フォーム全体 | バリデーション状態の表示確認 |

### Storybook Interaction Testing

Storybookの `play` 関数を使い、ストーリー上でユーザー操作をスクリプト化する。
コンポーネントの振る舞いを**視覚的に確認しながら**テストできる。

```typescript
import { within, userEvent, expect } from '@storybook/test';

export const FilledForm: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);

    // ユーザー操作をスクリプト化
    await userEvent.type(canvas.getByLabelText('メールアドレス'), 'user@example.com');
    await userEvent.type(canvas.getByLabelText('パスワード'), 'password123');
    await userEvent.click(canvas.getByRole('button', { name: 'ログイン' }));

    // アサーション
    await expect(canvas.getByText('ログイン成功')).toBeInTheDocument();
  },
};
```

**Testing Library との使い分け**:

| 用途 | ツール | 理由 |
|------|--------|------|
| ロジック・振る舞いの網羅的テスト | Testing Library（Vitest / Jest） | 高速・CI向き |
| UIの視覚確認 + 動作検証 | Storybook Interaction Testing | 目視確認・デバッグ向き |
| 見た目の変更検出 | VRT（Storycap + reg-suit） | ピクセル単位の差分検出 |

### テストレベル判断フロー

何をテストしたいかに応じて、最適なテストレベルを選択する：

```
テストしたい内容
    ↓
「ロジック」が複雑？（計算、データ変換、条件分岐）
    ├─ Yes → Unit テスト（Vitest / Jest）
    └─ No ↓
「UIの振る舞い」を保証したい？（操作→表示変化）
    ├─ Yes → Integration テスト（Testing Library）
    └─ No ↓
「見た目」の崩れを防ぎたい？（CSS、レイアウト）
    ├─ Yes → VRT（Storycap + reg-suit）
    └─ No ↓
「重要機能」の連携を確認したい？（ログイン、決済）
    └─ Yes → E2E テスト（Playwright）← 最小限に絞る
```

---

## テストデータ設計の落とし穴

### 時間フィルタ付きクエリのテスト

`WHERE timestamp >= Date.now() - N日` のようなクエリをテストする場合、固定の過去日付をテストデータに使うとフィルタ範囲外になり検索結果が空になる。

```typescript
// ❌ BAD: 固定日付は時間経過でフィルタ範囲外になる
const timestampMs = new Date("2025-01-15T12:00:00Z").getTime();

// ✅ GOOD: Date.now() 基準の相対日付で常にフィルタ範囲内
const timestampMs = Date.now() - 2 * 24 * 60 * 60 * 1000; // 2日前
```

**ポイント**: プロダクションコードが `Date.now()` を基準にフィルタしている場合、テストデータも `Date.now()` 基準で生成する。

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
- [Kent C. Dodds - Testing Trophy](https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications)
- [Testing Library - Guiding Principles](https://testing-library.com/docs/guiding-principles)
- [MSW - Mock Service Worker](https://mswjs.io/)
- [フロントエンド開発のためのテスト入門](https://www.shoeisha.co.jp/book/detail/9784798178639)
