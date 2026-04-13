## 大規模レンダリングのパフォーマンス最適化

大量の DOM 要素を扱うコンポーネント（リスト、テーブル、diff 表示等）で、レンダリングパフォーマンスを改善するための戦略。

参考: [GitHub Engineering - The uphill climb of making diff lines performant](https://github.blog/engineering/architecture-optimization/the-uphill-climb-of-making-diff-lines-performant/)

---

### 段階的戦略

パフォーマンス最適化は単一の銀の弾丸ではなく、段階的に適用する。

| 段階 | 戦略 | 対象 | トレードオフ |
|------|------|------|-------------|
| 1 | コンポーネント構造の簡素化 | すべてのケース | なし（純粋な改善） |
| 2 | イベント・ステート設計の見直し | 中〜大規模 | コードの抽象度が下がる |
| 3 | 仮想化（Virtualization） | p95 超の巨大ケース | find-in-page 等が壊れる |

仮想化は最終手段。まず構造改善で通常ケースを高速化し、仮想化は極端なケースだけに適用する。

---

### 1. コンポーネント構造の簡素化

#### 共通抽象化の分離

複数のビューモードを1つの共通コンポーネントで抽象化すると、条件分岐・余分な props 伝播が蓄積する。DOM 構造が根本的に異なるモードは**専用コンポーネントに分離**する。

```tsx
// BAD: 共通抽象化（条件分岐の蓄積）
function DiffLine({ mode, ...props }: Props) {
  if (mode === 'unified') { /* ... */ }
  if (mode === 'split') { /* ... */ }
}

// GOOD: モードごとに専用コンポーネント
function UnifiedDiffLine(props: UnifiedProps) { /* unified に最適化 */ }
function SplitDiffLine(props: SplitProps) { /* split に最適化 */ }
```

#### DOM 要素数の削減

1要素あたりの削減は微小でも、N 倍のスケールで劇的に効く。

- ラッパー `<div>` の排除（Fragment、CSS での解決）
- 条件付きレンダリングの徹底（非表示要素を DOM に残さない）
- コンポーネント階層のフラット化

> 1行あたり DOM ノード2個の削減 → 10,000行で20,000ノードの削減

---

### 2. イベント・ステート設計の見直し

#### イベント委譲（Event Delegation）

各要素にハンドラをバインドする代わりに、親に単一ハンドラを置き `data-*` 属性で対象を識別する。

```tsx
// BAD: N 個の関数オブジェクト生成 + メモ化が壊れやすい
{lines.map(line => (
  <tr onClick={() => handleClick(line.number, line.path)}>
))}

// GOOD: 親に1つのハンドラ、data 属性で識別
<tbody onClick={handleClick}>
  {lines.map(line => (
    <tr data-line-number={line.number} data-file-path={line.path}>
  ))}
</tbody>

function handleClick(e: React.MouseEvent) {
  const row = (e.target as HTMLElement).closest('tr');
  const lineNum = row?.dataset.lineNumber;
  const path = row?.dataset.filePath;
}
```

効果:
- 関数オブジェクトが N 個 → 1 個（メモリ削減、GC 負荷減）
- 行コンポーネントから `onClick` props が消え、`React.memo` が効きやすくなる
- `dataset` の値は常に `string` — 数値が必要なら `Number()` で変換

#### ステート配置の最適化

重いコンテンツ（コメント入力欄、コンテキストメニュー等）の状態を行コンポーネント自体に持たせず、**条件付きでマウントされる子コンポーネント**に移動する。

```tsx
// BAD: 行が状態を持つ → 状態変更で行全体が再レンダリング
function Row() {
  const [isEditing, setIsEditing] = useState(false);
  return <tr>...</tr>;
}

// GOOD: 行はステートレス、編集 UI は必要時のみマウント
function Row() { return <tr>...</tr>; } // React.memo が効く
{editingRowId === row.id && <Editor rowId={row.id} />}
```

#### O(1) データアクセス

繰り返し参照されるデータは事前に Map 化し、ループ内の O(n) 探索を排除する。

```tsx
// BAD: 毎行で線形探索
comments.filter(c => c.path === path && c.line === lineNum) // O(n)

// GOOD: 事前構築した Map
const commentsMap = new Map<string, Map<string, Comment[]>>();
commentsMap.get(path)?.get(`L${lineNum}`) // O(1)
```

#### useEffect の制限

大量レンダリングされるコンポーネントでは `useEffect` を禁止し、トップレベルコンポーネントに限定する。lint ルールで強制することで、メモ化の確実性を担保する。

---

### 3. 仮想化（最終手段）

TanStack Virtual 等で表示領域のみレンダリングする。

```tsx
const virtualizer = useVirtualizer({
  count: items.length,
  getScrollElement: () => parentRef.current,
  estimateSize: () => rowHeight,
});
```

**トレードオフ**:
- ブラウザの find-in-page（Ctrl+F）が DOM 外の要素にヒットしない
- アクセシビリティ（スクリーンリーダー）への影響
- スクロール位置の復元が複雑になる

仮想化の適用基準を明確にし、通常ケースではブラウザのネイティブ機能を維持する。

---

### CSS パフォーマンス

| 避ける | 代替 | 理由 |
|--------|------|------|
| `:has()` セレクタ（動的切替） | クラス名の付け替え | 親方向の DOM 逆走査が重い |
| レイアウトを変える `left/top` | `transform: translate()` | GPU コンポジットレイヤーで処理 |
| 複雑なセレクタチェーン | フラットなクラス名 | セレクタマッチングコスト削減 |

---

### 計測と監視

改善は計測に基づいて行う。推測で最適化しない。

| 指標 | 計測方法 | 目安 |
|------|---------|------|
| INP（Interaction to Next Paint） | web-vitals ライブラリ / Lighthouse | < 200ms |
| DOM ノード数 | DevTools Performance Monitor | < 1,500（推奨） |
| JS ヒープ使用量 | DevTools Memory | アプリ規模による |
| コンポーネントレンダリング回数 | React DevTools Profiler | 不要な再レンダーがないこと |

INP はインタラクション単位で追跡し、Datadog 等のダッシュボードで p50/p95/p99 を監視する。
