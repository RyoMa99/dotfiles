---
name: web-frontend
description: "Webフロントエンド設計原則。コンポーネント設計、CSSレイアウト、Design Tokens、フォームバリデーション、パフォーマンス最適化。フロントエンド開発・レビュー時に参照。"
disable-model-invocation: false
---

CSSレイアウト・レスポンシブ・Design Tokens については `css-layout.md` を Read して参照。

# Webフロントエンド設計原則

Future Architect「Webフロントエンド設計ガイドライン」等を参考にしたフロントエンド固有の設計原則。

関連: @~/.claude/rules/robust-code.md（型による予防的設計）
関連: /TDD スキル内のテスト原則を参照
関連: /security-review スキル内のチェックリストを参照

---

## コンポーネント設計

### 共通コンポーネント vs 業務コンポーネント

| 分類 | 責務 | 例 | 配置 |
|------|------|-----|------|
| **共通（UI）** | 見た目と汎用操作 | Button, Input, Modal, Table | `components/ui/` |
| **業務（Feature）** | ドメインロジックを含む | OrderForm, UserProfile | `features/{feature}/components/` |

### 設計原則

```
共通コンポーネント:
  - ドメイン知識を持たない
  - props で振る舞いを制御
  - デザインシステムに準拠
  - Storybook でカタログ化

業務コンポーネント:
  - 特定のユースケースに特化
  - 共通コンポーネントを組み合わせて構築
  - データ取得・状態管理を含んでよい
```

### アンチパターン

```typescript
// BAD: 共通コンポーネントにドメインロジック
function Button({ label, onClick, isOrderSubmit }: Props) {
  if (isOrderSubmit) {
    // 注文固有のロジックが混入
    validateOrder();
  }
  return <button onClick={onClick}>{label}</button>;
}

// GOOD: 業務コンポーネントが共通コンポーネントを使う
function OrderSubmitButton({ order }: Props) {
  const handleClick = () => {
    validateOrder(order);
    submitOrder(order);
  };
  return <Button label="注文する" onClick={handleClick} />;
}
```

### Props設計の原則

```typescript
// BAD: boolean props の乱用（組み合わせ爆発）
<Button primary large disabled loading />

// GOOD: variant パターンで制約
type ButtonVariant = "primary" | "secondary" | "ghost";
type ButtonSize = "sm" | "md" | "lg";

interface ButtonProps {
  variant: ButtonVariant;
  size: ButtonSize;
  disabled?: boolean;
  children: ReactNode;
}
```

---

## ディレクトリ構成

### features/ ベースの構成

機能単位でコードをまとめ、変更の影響範囲を局所化する。

```
src/
├── app/                    # ルーティング・レイアウト（Next.js App Router等）
│   ├── layout.tsx
│   └── (routes)/
├── features/               # 機能単位のモジュール
│   ├── auth/
│   │   ├── components/     # 機能固有のコンポーネント
│   │   ├── hooks/          # 機能固有のhooks
│   │   ├── api/            # API呼び出し
│   │   ├── types/          # 型定義
│   │   └── index.ts        # 公開API（再エクスポート）
│   ├── orders/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── api/
│   │   └── types/
│   └── ...
├── components/             # 共通UIコンポーネント
│   └── ui/
├── hooks/                  # 共通hooks
├── lib/                    # ユーティリティ・設定
└── types/                  # グローバル型定義
```

### 依存ルール

```
features/auth/ は features/orders/ を直接 import しない
  → 共通部分は components/ や hooks/ に切り出す
  → features 間の結合を防ぐ
```

### index.ts による公開API制御

```typescript
// features/auth/index.ts
// 外部に公開するものだけをエクスポート
export { LoginForm } from './components/LoginForm';
export { useAuth } from './hooks/useAuth';
export type { User, AuthState } from './types';

// 内部実装は公開しない
// ❌ export { validatePassword } from './utils/validation';
```

---

## フォームバリデーション

### 3段階バリデーション

| 段階 | タイミング | 目的 | 実装 |
|------|-----------|------|------|
| **1. インライン** | 入力中・フォーカスアウト時 | 即時フィードバック | HTML5 / Zod + React Hook Form |
| **2. 送信時** | Submit時 | 全フィールドの整合性チェック | フォームライブラリ |
| **3. サーバー** | API応答後 | ビジネスルール検証 | API エラーレスポンス |

### 実装パターン

```typescript
// Zod でスキーマ定義（フロント・バックエンド共有可能）
const orderSchema = z.object({
  email: z.string().email("有効なメールアドレスを入力してください"),
  quantity: z.number().min(1, "1以上を指定してください").max(100, "100以下を指定してください"),
  shippingDate: z.date().min(new Date(), "未来の日付を指定してください"),
});

// React Hook Form + Zod
const { register, handleSubmit, formState: { errors } } = useForm({
  resolver: zodResolver(orderSchema),
});
```

### エラー表示の原則

```typescript
// BAD: 送信後にまとめてエラーを表示
<div className="error-summary">
  {errors.map(e => <p>{e.message}</p>)}
</div>

// GOOD: 各フィールドの直下にインラインエラー
<div>
  <label htmlFor="email">メールアドレス</label>
  <input id="email" aria-describedby="email-error" aria-invalid={!!errors.email} />
  {errors.email && (
    <p id="email-error" role="alert">{errors.email.message}</p>
  )}
</div>
```

### サーバーエラーのマッピング

```typescript
// サーバーからのフィールド別エラーをフォームに反映
try {
  await submitOrder(data);
} catch (error) {
  if (error instanceof ApiValidationError) {
    // フィールド別にエラーをセット
    error.fieldErrors.forEach(({ field, message }) => {
      setError(field, { type: 'server', message });
    });
  }
}
```

---

## パフォーマンス

### キャッシュ戦略

| データ種類 | staleTime | キャッシュ方針 |
|-----------|-----------|---------------|
| マスターデータ（都道府県等） | 長い（24h+） | 積極的キャッシュ |
| 一覧データ | 中程度（1-5min） | バックグラウンド再取得 |
| 詳細データ | 短い（30s-1min） | アクセス時に再検証 |
| リアルタイムデータ | 0（常に最新） | WebSocket / SSE |

```typescript
// TanStack Query でのキャッシュ設定例
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60,     // 1分間はキャッシュを新鮮とみなす
      gcTime: 1000 * 60 * 5,    // 5分間キャッシュを保持
    },
  },
});

// マスターデータは長めに
useQuery({
  queryKey: ['prefectures'],
  queryFn: fetchPrefectures,
  staleTime: 1000 * 60 * 60 * 24, // 24時間
});
```

### バンドル最適化

| 手法 | 効果 | 実装 |
|------|------|------|
| **Code Splitting** | 初期ロード削減 | `React.lazy()` / Next.js dynamic import |
| **Tree Shaking** | 未使用コード除去 | ESM import + バンドラ設定 |
| **画像最適化** | 転送量削減 | `next/image` / WebP / AVIF |
| **フォント最適化** | FOUT/FOIT防止 | `font-display: swap` / サブセット化 |

```typescript
// Code Splitting: ルート単位で分割
const OrderPage = lazy(() => import('./features/orders/pages/OrderPage'));

// 重いライブラリの動的インポート
const handleExport = async () => {
  const { exportToExcel } = await import('./lib/excel-export');
  exportToExcel(data);
};
```

### リスト表示の最適化

```typescript
// 50件以上のリストは仮想化を検討
// @tanstack/react-virtual を使用
const virtualizer = useVirtualizer({
  count: items.length,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 48,
});
```

---

## フロントエンドテスト

バックエンドのテストピラミッドとは異なり、フロントエンドでは**テストトロフィー**モデルを採用する。

テストの一般原則（偽陽性/偽陰性、テストダブル、テストサイズ等）は /TDD スキル内のテスト原則を参照。

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

バックエンドは Unit テストが最多（ドメインロジック中心）だが、フロントエンドは Integration テストが最多（コンポーネント結合の振る舞い中心）。

### テストレベル判断フロー

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

### テスト観点マトリクス

| テスト対象 | テスト種類 | ツール | 確認内容 |
|-----------|-----------|--------|---------|
| ユーティリティ関数 | Unit | Vitest / Jest | 入出力の正しさ |
| カスタム hooks | Unit / Integration | renderHook / テスト用コンポーネント | 状態遷移、副作用 |
| 単一コンポーネント | Integration | Testing Library | 表示・操作・a11y |
| フォーム | Integration | Testing Library | バリデーション・送信・エラー表示 |
| ページ（複数コンポーネント結合） | Integration | Testing Library + MSW | データ取得・表示・操作の統合 |
| ユーザーフロー | E2E | Playwright / Cypress | 画面遷移を含む一連の操作 |
| ビジュアル | Visual Regression | Storycap + reg-suit | UIの意図しない変更検出 |

### Integration テスト

#### fireEvent vs userEvent

| API | 挙動 | 推奨 |
|-----|------|------|
| `fireEvent` | DOM イベントを単発で発火。フォーカス移動やキー入力の連続性を再現しない | 非推奨 |
| `userEvent` | 実際のブラウザ操作をシミュレーション（クリック→フォーカス→キーダウン→入力→キーアップ） | **推奨** |

```typescript
// BAD: fireEvent は単発イベント
fireEvent.change(input, { target: { value: 'hello' } });

// GOOD: userEvent は実際のユーザー操作を再現
const user = userEvent.setup();
await user.type(input, 'hello');
```

#### Testing Library のユーザー視点アプローチ

```typescript
// BAD: 実装の詳細をテスト（shallow + state 直接参照）
const wrapper = shallow(<LoginForm />);
expect(wrapper.state('email')).toBe('user@example.com');

// GOOD: ユーザーの視点でテスト
it('メールアドレスを入力してログインできる', async () => {
  const user = userEvent.setup();
  render(<LoginForm onSubmit={mockSubmit} />);
  await user.type(screen.getByLabelText('メールアドレス'), 'user@example.com');
  await user.type(screen.getByLabelText('パスワード'), 'password123');
  await user.click(screen.getByRole('button', { name: 'ログイン' }));
  expect(mockSubmit).toHaveBeenCalledWith({ email: 'user@example.com', password: 'password123' });
});
```

#### クエリの優先順位

| 優先度 | クエリ | 用途 |
|--------|--------|------|
| 1（推奨） | `getByRole` | ボタン、リンク、フォーム要素 |
| 2 | `getByLabelText` | フォームフィールド |
| 3 | `getByPlaceholderText` | label がない場合のフォールバック |
| 4 | `getByText` | テキスト表示要素 |
| 5 | `getByDisplayValue` | フォーム要素の現在の入力値 |
| 6（最終手段） | `getByTestId` | 他のクエリで特定できない場合のみ |

**`getByRole` のパフォーマンス注意**: 内部で ARIA ロール計算を行うため遅い。大規模テストスイートでタイムアウトが頻発する場合は `getByText` / `getByLabelText` へのフォールバックを検討。

#### jest-dom カスタムマッチャー

| マッチャー | 用途 |
|-----------|------|
| `toBeInTheDocument()` | DOM に存在するか |
| `toHaveTextContent()` | テキストを含むか |
| `toBeDisabled()` / `toBeEnabled()` | 有効・無効状態 |
| `toBeVisible()` | 視覚的に表示されているか |
| `toBeInvalid()` | `aria-invalid="true"` 状態か |
| `toHaveAttribute()` | 属性値の検証 |

```typescript
// BAD: DOM プロパティを直接参照
expect(button.disabled).toBe(true);

// GOOD: カスタムマッチャーで意図を明確に
expect(button).toBeDisabled();
```

#### 非同期テストの待機

```typescript
// findBy: 要素が非同期に出現する場合
const message = await screen.findByRole('alert');

// waitFor: 特定のアサーションが通るまでリトライ
await waitFor(() => {
  expect(screen.getByRole('textbox')).toHaveErrorMessage('既に使用されています');
});
```

### アクセシビリティテスト

axe-core を組み込み、a11y 違反を自動検出する。

```typescript
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

it('アクセシビリティ違反がない', async () => {
  const { container } = render(<OrderForm />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

**検出できるもの**: label 欠落、コントラスト比不足、aria 属性の不正使用、見出しレベルスキップ、alt テキスト欠落。
**検出できないもの**: キーボード操作の使い勝手、スクリーンリーダーの読み上げ順序、認知的負荷。自動テストは最低限の品質担保であり、手動テストも併用する。

### MSW（Mock Service Worker）

API モックは MSW で統一し、テストとローカル開発で共有する。setup/teardown は `beforeAll(() => server.listen())`, `afterEach(() => server.resetHandlers())`, `afterAll(() => server.close())`。

```typescript
export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }]);
  }),
];

// エラーケースのテスト
it('API エラー時にエラーメッセージを表示する', async () => {
  server.use(
    http.get('/api/users', () => HttpResponse.json({ message: 'Error' }, { status: 500 })),
  );
  render(<UserList />);
  expect(await screen.findByRole('alert')).toHaveTextContent('データの取得に失敗しました');
});
```

### テストパターン集

#### Provider ラップ

```typescript
function renderWithProviders(ui: ReactElement) {
  return render(
    <QueryClientProvider client={new QueryClient()}>
      <ToastProvider>{ui}</ToastProvider>
    </QueryClientProvider>
  );
}
```

#### カスタム hooks のテスト

`renderHook` よりも**テスト用コンポーネントで振る舞いを検証**するアプローチを推奨。`renderHook` が適切な場面は副作用のない純粋な状態計算ロジックのみ。

```typescript
const TestComponent = () => {
  const { count, increment } = useCounter();
  return <button onClick={increment}>{count}</button>;
};

it('ボタンクリックでカウントが増える', async () => {
  const user = userEvent.setup();
  render(<TestComponent />);
  await user.click(screen.getByRole('button'));
  expect(screen.getByRole('button')).toHaveTextContent('1');
});
```

#### テストデータのファクトリ関数

```typescript
function createUser(overrides?: Partial<User>): User {
  return { id: '1', name: 'テスト太郎', email: 'test@example.com', role: 'member', ...overrides };
}

const admin = createUser({ role: 'admin' });
```

#### Next.js ルーターのモック

```typescript
jest.mock('next/navigation', () => ({ useRouter: jest.fn() }));

it('詳細ページへ遷移する', async () => {
  const push = jest.fn();
  (useRouter as jest.Mock).mockReturnValue({ push });
  const user = userEvent.setup();
  render(<DetailButton id="123" />);
  await user.click(screen.getByRole('button', { name: '詳細を見る' }));
  expect(push).toHaveBeenCalledWith('/details/123');
});
```

### スナップショットテスト

**フロントエンドでは非推奨**。些細な変更で壊れやすく（Brittle Test）、開発者が盲目的に更新しバグを見逃す。代替: ロジック→アサーション、見た目→VRT。

### ビジュアルリグレッションテスト（VRT）

CSS の変更による意図しない UI 崩れをスクリーンショット差分で検出する。Unit / Integration テストでは検出できない。

#### Storycap + reg-suit

```bash
npx storycap http://localhost:6006 --outDir ./screenshots/actual
npx reg-suit compare
open ./reg-suit-report/index.html
```

**対象の選定**: 共通UIコンポーネント（影響範囲大）、レイアウトコンポーネント（位置崩れ検出）、フォーム全体（バリデーション状態）に絞る。

### E2E テストの安定性（Flaky テスト対策）

| 対策 | 説明 |
|------|------|
| **DB リセット** | テスト実行ごとにクリーンな状態で開始 |
| **リソース隔離** | テスト間で競合しないよう独立データを作成 |
| **適切な待機** | Playwright の自動待機機能を活用。`sleep` に頼らない |
| **リトライ戦略** | Flaky テストの一時対策として、テスト単位のリトライを設定 |

---

## Storybook 活用

### コンポーネントカタログ

共通UIコンポーネントをStorybookで管理し、**アプリケーションコードから独立して開発・確認**する。

```typescript
// Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  component: Button,
  argTypes: {
    variant: { control: 'select', options: ['primary', 'secondary', 'ghost'] },
    size: { control: 'select', options: ['sm', 'md', 'lg'] },
  },
};
export default meta;

type Story = StoryObj<typeof Button>;

export const Primary: Story = {
  args: { variant: 'primary', children: 'ボタン' },
};

export const AllVariants: Story = {
  render: () => (
    <div className="flex gap-4">
      <Button variant="primary">Primary</Button>
      <Button variant="secondary">Secondary</Button>
      <Button variant="ghost">Ghost</Button>
    </div>
  ),
};
```

### Interaction Testing

`play` 関数でユーザー操作をスクリプト化し、**視覚的に確認しながら**テストする。

```typescript
import { within, userEvent, expect } from '@storybook/test';

export const WithValidation: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole('button', { name: '送信' }));
    await expect(canvas.getByText('入力してください')).toBeInTheDocument();
  },
};
```

**Testing Library との使い分け**:

| 用途 | ツール | 理由 |
|------|--------|------|
| ロジック・振る舞いの網羅的テスト | Testing Library（Vitest / Jest） | 高速・CI向き |
| UIの視覚確認 + 動作検証 | Storybook Interaction Testing | 目視確認・デバッグ向き |
| 見た目の変更検出 | VRT（Storycap + reg-suit） | ピクセル単位の差分検出 |

### ストーリー設計のガイドライン

| ストーリー | 目的 |
|-----------|------|
| Default | デフォルト状態 |
| AllVariants | variant の一覧表示 |
| WithLongText | 長いテキストでの表示崩れ確認 |
| Loading / Error | 非同期状態の表示 |
| Interactive | `play` 関数による操作テスト |

### addon-a11y によるアクセシビリティチェック

`@storybook/addon-a11y` を導入すると、各ストーリーに対して axe-core ベースのアクセシビリティ自動検知が有効になる。コントラスト比不足、代替テキスト欠如、ラベル不備などをコンポーネント開発時に即座に検出できる。

`@storybook/test-runner` + `axe-playwright` との組み合わせで、CI 上での全ストーリー a11y テスト自動化も可能（`npx test-storybook`）。

---

## チェックリスト

フロントエンド実装時に確認：

### コンポーネント設計
- [ ] 共通コンポーネントにドメインロジックが混入していないか
- [ ] Props は variant パターン等で組み合わせを制約しているか
- [ ] 適切な粒度に分割されているか（大きすぎ / 小さすぎ）

### フォーム
- [ ] バリデーションスキーマを定義しているか（Zod等）
- [ ] インラインエラー表示を実装しているか
- [ ] サーバーエラーをフォームにマッピングしているか

### パフォーマンス
- [ ] 重いコンポーネント・ライブラリを動的インポートしているか
- [ ] 長いリストに仮想化を適用しているか
- [ ] 画像に適切なフォーマット・サイズを使用しているか

### CSSレイアウト
- [ ] ページレベルの分割に Grid `minmax(0,1fr)` を使っているか（Flex のネスト伝播問題を回避）
- [ ] 余白は親要素の `gap` で管理し、子要素にマージンを持たせていないか
- [ ] 固定幅・固定高さを避け、`max-w` やコンテンツベースのサイズを使っているか
- [ ] メディアクエリの代わりにコンテナクエリや `auto-fit` を検討したか
- [ ] テキスト幅を `max-w-[65ch]` 等で読みやすく制限しているか

### レスポンシブ
- [ ] モバイルファーストで実装しているか（プレフィックスなし = モバイル）
- [ ] ブレークポイントがプロジェクト全体で統一されているか

### Design Tokens
- [ ] カラーは役割ベースで命名しているか（`primary`, `destructive` 等）
- [ ] フォントサイズは `rem` ベースのスケールを使用しているか

### テスト
- [ ] テストトロフィーに従い Integration テストを中心に書いているか
- [ ] `userEvent` を使用しているか（`fireEvent` ではなく）
- [ ] `getByRole` > `getByLabelText` > `getByText` の優先順位に従っているか
- [ ] axe-core による a11y テストを含めているか

### Storybook
- [ ] 共通UIコンポーネントのストーリーを作成しているか
- [ ] 主要なバリエーション（状態、サイズ、エラー等）をカバーしているか
- [ ] addon-a11y でアクセシビリティ違反が検出されていないか

---

## 参考資料

- [Future Architect - Webフロントエンド設計ガイドライン](https://future-architect.github.io/coding-standards/documents/forFrontend/design_guidelines.html)
- [Bulletproof React](https://github.com/alan2207/bulletproof-react)
- [TanStack Query - Practical React Query](https://tkdodo.eu/blog/practical-react-query)
- [Every Layout](https://every-layout.dev/) - レイアウトプリミティブの設計パターン
- [OPTiM - FlexboxとGridの使い分け](https://tech-blog.optim.co.jp/entry/2025/12/01/150000) - min-width: auto の罠と Grid の利点
- [フロントエンド開発のためのテスト入門](https://www.shoeisha.co.jp/book/detail/9784798178639)
- [Kent C. Dodds - Testing Trophy](https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications)
- [Testing Library - Guiding Principles](https://testing-library.com/docs/guiding-principles)
- [MSW - Mock Service Worker](https://mswjs.io/)
- [koki_tech - フロントエンドのテスト戦略について考える](https://zenn.dev/koki_tech/articles/a96e58695540a7)
- [silverbirder - 網羅的Webフロントエンドテストパターンガイド](https://zenn.dev/silverbirder/articles/c3de04c9e6dd58)
- [Social Plus - フロントエンドのテスト](https://zenn.dev/socialplus/articles/b09827d74ff148)
