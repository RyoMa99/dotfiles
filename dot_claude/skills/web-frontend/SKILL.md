---
name: web-frontend
description: "Use when developing web frontend features - component design, React patterns, CSS layout, forms, and testing"
disable-model-invocation: false
---

参照ファイル:
- `react-patterns.md` — React 固有の State 管理、Hooks、Async React、React Hook Form
- `component-design.md` — テスト戦略、フォームバリデーション、パフォーマンス、Storybook
- `css-layout.md` — CSS レイアウト、レスポンシブ、Design Tokens

# Web フロントエンド設計原則

関連: `robust-code.md` ルール（型による予防的設計）
関連: `/TDD` スキル内のテスト原則を参照

---

## コンポーネント設計の核心

### 合成（Composition）

コンポーネントを小さな部品に分解し、組み合わせて機能を構築する。

| 分類 | 責務 | 配置 |
|------|------|------|
| **共通（UI）** | 見た目と汎用操作。ドメイン知識なし | `components/ui/` |
| **業務（Feature）** | ドメインロジック。共通を組み合わせて構築 | `features/{feature}/components/` |

```tsx
// BAD: 共通コンポーネントにドメインロジック
function Button({ label, onClick, isOrderSubmit }: Props) {
  if (isOrderSubmit) { validateOrder(); }
  return <button onClick={onClick}>{label}</button>;
}

// GOOD: 業務コンポーネントが共通を使う
function OrderSubmitButton({ order }: Props) {
  const handleClick = () => { validateOrder(order); submitOrder(order); };
  return <Button label="注文する" onClick={handleClick} />;
}
```

### Props 設計

```tsx
// BAD: boolean の乱用（組み合わせ爆発）
<Button primary large disabled loading />

// GOOD: variant で制約
type ButtonVariant = "primary" | "secondary" | "ghost";
<Button variant="primary" size="md">送信</Button>
```

### ディレクトリ構成

features/ ベースで機能単位にまとめる。features 間の直接 import を禁止し、共通部分は `components/` や `hooks/` に切り出す。各 feature の `index.ts` で公開 API を制御する。詳細は `component-design.md` を参照。

---

## State 分類フロー

React で最も重要な判断ポイント。State の種類を見極め、適切なツールを選ぶ。

```
サーバーから取得したデータ？
  ├─ Yes → TanStack Query / SWR（Server State）
  └─ No → 複数コンポーネントで共有？
            ├─ No → useState / useReducer（UI State）
            └─ Yes → 更新頻度高い？
                      ├─ Yes → Zustand / Jotai（App State）
                      └─ No → Context
```

State 設計の5ステップ: 視覚状態を列挙 → トリガを特定 → useState で表現 → 不要な state を削除 → ハンドラを接続

```tsx
// BAD: Server State を useState で管理
const [users, setUsers] = useState<User[]>([]);
useEffect(() => { fetchUsers().then(setUsers); }, []);

// GOOD: TanStack Query
const { data: users } = useQuery({ queryKey: ['users'], queryFn: fetchUsers });
```

---

## テストの方針

フロントエンドでは**テストトロフィー**モデルを採用。Integration テストが中心。

```
テストしたい内容
    ↓
「ロジック」が複雑？ → Unit テスト
「UIの振る舞い」？   → Integration テスト（Testing Library）← 主戦場
「見た目の崩れ」？   → VRT（Storycap + reg-suit）
「重要機能の連携」？ → E2E テスト（Playwright）← 最小限
```

詳細は `component-design.md` のテストセクションを参照。

---

## ヘルスチェック（react-doctor）

React プロジェクトの健全性を診断する。60以上のルール（セキュリティ、パフォーマンス、正確性、アクセシビリティ）と dead code 検出を実行し、0〜100 のスコアで評価する。

### 実行タイミング

| 場面 | コマンド | 目的 |
|------|---------|------|
| 新機能の実装完了後 | `react-doctor . --verbose` | 導入した問題の早期発見 |
| リファクタリング前 | `react-doctor . --verbose` | 現状のベースラインスコアを記録 |
| PR レビュー時 | `react-doctor . --diff main --verbose` | 変更ファイルのみスキャン |
| スコア確認のみ | `react-doctor . --score` | 素早くヘルススコアを取得 |

### スコア基準

| スコア | 評価 | 対応 |
|--------|------|------|
| 75〜100 | Great | 問題なし |
| 50〜74 | Needs work | Warning を優先的に対処 |
| 0〜49 | Critical | Error を最優先で修正 |

### 設定ファイル

プロジェクトルートに `react-doctor.config.json` を配置して、ルールやファイルを除外できる：

```json
{
  "ignore": {
    "rules": ["除外するルール名"],
    "files": ["src/generated/**"]
  }
}
```
