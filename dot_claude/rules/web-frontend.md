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

```css
/* BAD: デスクトップファーストで書いてモバイル対応 */
.container { width: 1200px; }
@media (max-width: 768px) { .container { width: 100%; } }

/* GOOD: モバイルファーストで書いてデスクトップ拡張 */
.container { width: 100%; }
@media (min-width: 768px) { .container { max-width: 1200px; } }
```

### ブレークポイント

プロジェクトで統一されたブレークポイントを定義する。Tailwind CSS のデフォルト値が一般的：

| 名前 | 値 | 対象 |
|------|-----|------|
| `sm` | 640px | スマートフォン横向き |
| `md` | 768px | タブレット |
| `lg` | 1024px | デスクトップ |
| `xl` | 1280px | 大画面 |

### コンテナクエリ

親要素のサイズに応じたスタイル変更（コンポーネントの再利用性向上）：

```css
.card-container { container-type: inline-size; }

@container (min-width: 400px) {
  .card { display: flex; flex-direction: row; }
}
```

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

### レスポンシブ
- [ ] モバイルファーストで実装しているか
- [ ] ブレークポイントがプロジェクト全体で統一されているか

---

## 参考資料

- [Future Architect - Webフロントエンド設計ガイドライン](https://future-architect.github.io/coding-standards/documents/forFrontend/design_guidelines.html)
- [Bulletproof React](https://github.com/alan2207/bulletproof-react)
- [TanStack Query - Practical React Query](https://tkdodo.eu/blog/practical-react-query)
