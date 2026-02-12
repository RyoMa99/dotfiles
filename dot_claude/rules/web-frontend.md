# Webフロントエンド設計原則

Future Architect「Webフロントエンド設計ガイドライン」等を参考にしたフロントエンド固有の設計原則。

関連: @~/.claude/rules/robust-code.md（型による予防的設計）
関連: @~/.claude/rules/testing.md（フロントエンドテストセクション）
関連: @~/.claude/rules/security.md（フロントエンド認証セクション）

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

## 状態管理

### 3分類

フロントエンドの状態は3種類に分類し、それぞれに適したツールを選択する。

| 分類 | 説明 | 例 | 推奨ツール |
|------|------|-----|-----------|
| **UI State** | 画面表示に関する一時的な状態 | モーダル開閉、タブ選択、フォーム入力中の値 | `useState` / `useReducer` |
| **App State** | アプリ全体で共有する状態 | ログインユーザー、テーマ設定、通知 | Context / Zustand / Jotai |
| **Server State** | サーバーから取得したデータのキャッシュ | ユーザー一覧、商品データ、検索結果 | TanStack Query / SWR |

### ツール選定フロー

```
この状態はサーバーから取得したデータ？
  ├─ Yes → TanStack Query / SWR（キャッシュ・再取得・楽観的更新）
  └─ No → 複数コンポーネントで共有？
            ├─ No → useState / useReducer（ローカル状態）
            └─ Yes → 更新頻度は高い？
                      ├─ Yes → Zustand / Jotai（リレンダリング最適化）
                      └─ No → Context（低頻度の共有状態）
```

### アンチパターン

```typescript
// BAD: Server State を useState で管理
const [users, setUsers] = useState<User[]>([]);
const [loading, setLoading] = useState(false);
const [error, setError] = useState<Error | null>(null);

useEffect(() => {
  setLoading(true);
  fetchUsers()
    .then(setUsers)
    .catch(setError)
    .finally(() => setLoading(false));
}, []);

// GOOD: TanStack Query で Server State を管理
const { data: users, isLoading, error } = useQuery({
  queryKey: ['users'],
  queryFn: fetchUsers,
});
```

```typescript
// BAD: グローバルに何でも入れる
const useGlobalStore = create((set) => ({
  user: null,
  theme: 'light',
  modalOpen: false,        // UI State を混入
  searchResults: [],       // Server State を混入
  formDraft: {},           // ローカル状態を混入
}));

// GOOD: 責務で分離
// Server State → TanStack Query
// UI State → コンポーネントローカル
// App State → 必要最小限のみストアに
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

## レスポンシブデザイン

### モバイルファースト

Tailwind はモバイルファースト設計。プレフィックスなしがベース（モバイル）、`md:` 以上で拡張する。

```tsx
// BAD: デスクトップ前提で書いてモバイル対応を後付け
<div className="w-[1200px] md:w-full">  // ← 逆

// GOOD: モバイルファーストで書いてデスクトップ拡張
<div className="w-full md:max-w-5xl">
```

### ブレークポイント

Tailwind CSS のデフォルトブレークポイント（`min-width` ベース）：

| プレフィックス | 値 | 対象 |
|--------------|-----|------|
| なし | 0px〜 | モバイル（ベース） |
| `sm:` | 640px〜 | スマートフォン横向き |
| `md:` | 768px〜 | タブレット |
| `lg:` | 1024px〜 | デスクトップ |
| `xl:` | 1280px〜 | 大画面 |

### コンテナクエリ

画面幅ではなく**親要素の幅**に応じてスタイルを変える。コンポーネントの再利用性が向上する。

```tsx
// 親要素をコンテナとして定義
<div className="@container">
  {/* コンテナ幅400px以上で横並び */}
  <div className="flex flex-col @md:flex-row gap-4">
    <Sidebar />
    <Main />
  </div>
</div>
```

> メディアクエリ（画面幅）よりコンテナクエリ（親要素幅）を優先する。
> コンポーネントが「どこに配置されるか」に依存しない設計になる。

---

## CSSレイアウト設計（Tailwind）

『Every Layout』のレイアウトプリミティブをTailwindで実装する。
メディアクエリに頼らず、コンテンツとコンテナのサイズに自動適応するレイアウトを構築する。

### 設計思想: コンポジション

巨大なコンポーネントにスタイルを詰め込むのではなく、**単一責任のレイアウトプリミティブを組み合わせる**。

```tsx
// BAD: 1つのコンポーネントにレイアウト・装飾・余白を混在
<div className="flex flex-col md:flex-row gap-4 p-6 bg-white rounded-lg shadow-md border">
  {/* すべてが1つのdivに依存 */}
</div>

// GOOD: レイアウト（配置）と装飾（見た目）を分離
<Stack gap={6}>           {/* 余白管理 */}
  <Card>                  {/* 装飾 */}
    <Cluster gap={4}>     {/* 水平配置 */}
      <Tag>React</Tag>
      <Tag>TypeScript</Tag>
    </Cluster>
  </Card>
</Stack>
```

### 余白管理の原則

> 要素自身にマージンを持たせず、**親（レイアウトプリミティブ）が子の間隔を管理する**。

```tsx
// BAD: 各要素が自分のマージンを持つ（コンテキストで破綻する）
<h2 className="mb-4">見出し</h2>
<p className="mb-4">本文</p>
<p className="mb-4">本文</p>  {/* 最後の要素にも不要なマージン */}

// GOOD: 親が子の間隔を管理（space-y / gap）
<div className="space-y-4">
  <h2>見出し</h2>
  <p>本文</p>
  <p>本文</p>
</div>
```

### Every Layout パターン

#### Stack: 垂直方向の配置

要素を縦に積み重ね、間隔を均一に管理する。最も基本的なパターン。

```tsx
<div className="flex flex-col gap-4">
  <Header />
  <Main />
  <Footer />
</div>

{/* Tailwind の space-y でも同等 */}
<div className="space-y-4">
  <h2>タイトル</h2>
  <p>本文</p>
  <p>本文</p>
</div>
```

#### Cluster: 水平方向の配置と折り返し

タグクラウドやボタン群など、**幅が足りなければ自動で折り返す**。

```tsx
<div className="flex flex-wrap gap-2">
  <span className="rounded-full bg-blue-100 px-3 py-1 text-sm">React</span>
  <span className="rounded-full bg-blue-100 px-3 py-1 text-sm">TypeScript</span>
  <span className="rounded-full bg-blue-100 px-3 py-1 text-sm">Tailwind</span>
</div>
```

#### Sidebar: メイン・サブの2カラム

**メディアクエリなし**で、幅が狭くなったら自動で縦並びに切り替わる。

```tsx
{/* サイドバー固定幅 + メインが残りを埋める */}
<div className="flex flex-wrap gap-4">
  <aside className="w-64 shrink-0 grow-0">サイドバー</aside>
  <main className="min-w-[50%] grow">メインコンテンツ</main>
</div>
```

`min-w-[50%]` がポイント: メインコンテンツの幅が50%を下回ると折り返す。

#### Switcher: 閾値による水平↔垂直の切り替え

**コンテナ幅**がある閾値より狭くなったら、水平→垂直に自動切り替え。

```tsx
{/* コンテナクエリで閾値ベースの切り替え */}
<div className="@container">
  <div className="flex flex-col @md:flex-row gap-4">
    <div className="flex-1">カード1</div>
    <div className="flex-1">カード2</div>
    <div className="flex-1">カード3</div>
  </div>
</div>

{/* または CSS Grid の auto-fit で自動カラム調整 */}
<div className="grid grid-cols-[repeat(auto-fit,minmax(250px,1fr))] gap-4">
  <div>カード1</div>
  <div>カード2</div>
  <div>カード3</div>
</div>
```

#### Cover: 垂直方向の中央揃え

ファーストビューや全画面セクションで、メインコンテンツを中央に配置する。

```tsx
<div className="flex min-h-screen flex-col">
  <header>ヘッダー</header>
  <main className="flex flex-1 items-center justify-center">
    <h1>中央に表示されるコンテンツ</h1>
  </main>
  <footer>フッター</footer>
</div>
```

#### Grid: レスポンシブグリッド

`auto-fit` + `minmax` で、**メディアクエリなし**にカラム数を自動調整。

```tsx
{/* 各カードが最低250px、余白があれば自動で列を増やす */}
<div className="grid grid-cols-[repeat(auto-fit,minmax(250px,1fr))] gap-6">
  {items.map(item => <Card key={item.id} {...item} />)}
</div>
```

### 内在的Webデザイン

固定値を避け、コンテンツに基づいてサイズが決まる設計。

```tsx
// BAD: 固定幅・固定高さ
<div className="w-[800px] h-[600px]">

// GOOD: 最大幅で制約し、高さはコンテンツに任せる
<div className="max-w-3xl">

// GOOD: 読みやすい行幅（約60〜70文字）を ch 単位で制限
<p className="max-w-[65ch]">本文テキスト...</p>
```

| 指針 | BAD | GOOD |
|------|-----|------|
| 幅 | `w-[800px]` | `max-w-3xl` |
| 高さ | `h-[600px]` | 指定なし（コンテンツに任せる） |
| テキスト幅 | `max-w-2xl` | `max-w-[65ch]`（文字数ベース） |
| 単位 | `px` ベース | `rem` / `ch` ベース |

---

## Design Tokens

### モジュラースケール（タイポグラフィ）

任意のピクセル値ではなく、**数学的な比率**に基づくフォントサイズ体系を使用する。
Tailwind のデフォルトスケールは良い出発点だが、プロジェクトに合わせてカスタマイズする。

```typescript
// tailwind.config.ts
export default {
  theme: {
    fontSize: {
      xs:   ['0.75rem',  { lineHeight: '1rem' }],    // 12px
      sm:   ['0.875rem', { lineHeight: '1.25rem' }],  // 14px
      base: ['1rem',     { lineHeight: '1.5rem' }],    // 16px（基準）
      lg:   ['1.125rem', { lineHeight: '1.75rem' }],   // 18px
      xl:   ['1.25rem',  { lineHeight: '1.75rem' }],   // 20px
      '2xl': ['1.5rem',  { lineHeight: '2rem' }],      // 24px
      '3xl': ['1.875rem',{ lineHeight: '2.25rem' }],   // 30px
    },
  },
};
```

**原則**:
- `rem` を使用し、ユーザーのブラウザ設定（フォントサイズ変更）を尊重する
- 見出しのジャンプ率（サイズ差）を十分に確保し、視覚的な階層を明確にする
- 本文の `line-height` は `1.5` 〜 `1.7` を目安にする

### 機能的カラー命名

色の見た目ではなく、**役割**で命名する。テーマ切り替え（ダークモード等）で名前を変えずに済む。

```typescript
// tailwind.config.ts
export default {
  theme: {
    colors: {
      // BAD: 見た目で命名（ダークモードで破綻する）
      // blue: '#3b82f6',
      // red: '#ef4444',

      // GOOD: 役割で命名
      primary:    'var(--color-primary)',     // ブランドカラー
      accent:     'var(--color-accent)',      // 強調・アクション
      destructive:'var(--color-destructive)', // 危険操作
      background: 'var(--color-background)', // 背景
      foreground: 'var(--color-foreground)', // テキスト
      muted:      'var(--color-muted)',      // 補足テキスト
      border:     'var(--color-border)',      // ボーダー
    },
  },
};
```

```css
/* globals.css */
:root {
  --color-primary: #3b82f6;
  --color-background: #ffffff;
  --color-foreground: #0f172a;
}

.dark {
  --color-primary: #60a5fa;
  --color-background: #0f172a;
  --color-foreground: #f8fafc;
}
```

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

### ストーリー設計のガイドライン

| ストーリー | 目的 |
|-----------|------|
| Default | デフォルト状態 |
| AllVariants | variant の一覧表示 |
| WithLongText | 長いテキストでの表示崩れ確認 |
| Loading / Error | 非同期状態の表示 |
| Interactive | `play` 関数による操作テスト |

---

## チェックリスト

フロントエンド実装時に確認：

### コンポーネント設計
- [ ] 共通コンポーネントにドメインロジックが混入していないか
- [ ] Props は variant パターン等で組み合わせを制約しているか
- [ ] 適切な粒度に分割されているか（大きすぎ / 小さすぎ）

### 状態管理
- [ ] UI / App / Server State を適切に分類しているか
- [ ] Server State に TanStack Query / SWR を使用しているか
- [ ] 不要なグローバル状態を作っていないか

### フォーム
- [ ] バリデーションスキーマを定義しているか（Zod等）
- [ ] インラインエラー表示を実装しているか
- [ ] サーバーエラーをフォームにマッピングしているか

### パフォーマンス
- [ ] 重いコンポーネント・ライブラリを動的インポートしているか
- [ ] 長いリストに仮想化を適用しているか
- [ ] 画像に適切なフォーマット・サイズを使用しているか

### CSSレイアウト
- [ ] 余白は親要素（`gap` / `space-y`）で管理し、子要素にマージンを持たせていないか
- [ ] 固定幅・固定高さを避け、`max-w` やコンテンツベースのサイズを使っているか
- [ ] メディアクエリの代わりにコンテナクエリや `auto-fit` を検討したか
- [ ] テキスト幅を `max-w-[65ch]` 等で読みやすく制限しているか

### レスポンシブ
- [ ] モバイルファーストで実装しているか（プレフィックスなし = モバイル）
- [ ] ブレークポイントがプロジェクト全体で統一されているか

### Design Tokens
- [ ] カラーは役割ベースで命名しているか（`primary`, `destructive` 等）
- [ ] フォントサイズは `rem` ベースのスケールを使用しているか

### Storybook
- [ ] 共通UIコンポーネントのストーリーを作成しているか
- [ ] 主要なバリエーション（状態、サイズ、エラー等）をカバーしているか

---

## 参考資料

- [Future Architect - Webフロントエンド設計ガイドライン](https://future-architect.github.io/coding-standards/documents/forFrontend/design_guidelines.html)
- [Bulletproof React](https://github.com/alan2207/bulletproof-react)
- [TanStack Query - Practical React Query](https://tkdodo.eu/blog/practical-react-query)
- [Every Layout](https://every-layout.dev/) - レイアウトプリミティブの設計パターン
- [フロントエンド開発のためのテスト入門](https://www.shoeisha.co.jp/book/detail/9784798178639)
