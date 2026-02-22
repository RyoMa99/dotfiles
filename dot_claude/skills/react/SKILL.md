---
name: react
description: "React設計原則。State管理、useEffect、コンポーネントパターン、Async React、React Hook Form。React開発時に参照。"
disable-model-invocation: false
---

設計パターン・Async React・React Hook Form については `patterns.md` を Read して参照。

# React 設計原則

React 固有のルール・gotcha・判断フローに特化。基礎チュートリアルは公式ドキュメント参照。

関連: /web-frontend スキルを参照（コンポーネント設計、ディレクトリ構成）
関連: @~/.claude/rules/robust-code.md（型による予防的設計）
関連: `/TDD` スキル内のテスト原則を参照（フロントエンドテストセクション）

---

## コンポーネントの基本

- コンポーネント名は**大文字で始める**（小文字は HTML 要素として解釈される）
- JSX: 単一ルート要素を返す / すべてのタグを閉じる / 属性はキャメルケース（例外: `aria-*`, `data-*`）
- **コンポーネント定義のネスト禁止** — レンダーごとに再定義され、state がリセットされる

```tsx
// BAD: レンダーごとに Photo が再作成され state 消失
function Gallery() {
  function Photo() { return <img src="..." />; }
  return <Photo />;
}
```

### Props

- props は読み取り専用。デフォルト値は `undefined` のみ適用（`null` / `0` では適用されない）

---

## 条件付きレンダーとリスト

### `&&` の落とし穴

左辺が `0` だと `0` が表示される。必ず真偽値に変換する。

```tsx
// BAD: messageCount が 0 だと「0」が表示される
{messageCount && <p>新着メッセージ</p>}

// GOOD
{messageCount > 0 && <p>新着メッセージ</p>}
```

### key のルール

| ルール | 理由 |
|--------|------|
| 必須 | React がインスタンスの同一性を追跡 |
| 兄弟間で一意 | 異なる配列間では同じ key 可 |
| 変更不可 | key が変わると state がリセットされる |

```tsx
// BAD: index / Math.random() を key にする
{items.map((item, i) => <Item key={i} />)}         // 挿入・削除でバグ
{items.map(item => <Item key={Math.random()} />)}  // 毎回 state 消失

// GOOD: 一意な ID
{items.map(item => <Item key={item.id} {...item} />)}
```

---

## 純粋性と React のルール

### 3原則

1. **冪等性** — 同じ入力（props, state, context）→ 同じ JSX
2. **レンダー中の副作用禁止** — `new Date()`, `Math.random()`, DOM操作, API呼び出し不可
3. **外部値の変更禁止** — ローカルで作成した変数のミューテーションは許容

### 不変性ルール

| 対象 | ルール |
|------|--------|
| props | 書き換え禁止 |
| state | set 関数経由のみ |
| フックの引数・戻り値 | 書き換え禁止（メモ化が壊れる） |
| JSX に渡した値 | 渡した後は書き換えない |

一般原則は @~/.claude/rules/robust-code.md も参照。

### 副作用の配置

| 配置場所 | 用途 | 優先度 |
|---------|------|--------|
| **イベントハンドラ** | ユーザー操作に応じた処理 | 第一選択 |
| **`useEffect`** | 外部システムとの同期 | 最終手段 |

### フックのルール

1. **トップレベルでのみ呼び出す** — 条件分岐、ループ、ネスト関数、try/catch 内は禁止
2. **React 関数内でのみ呼び出す** — コンポーネントまたはカスタムフック内
3. **通常の値として扱わない** — props 渡し、変数格納での動的呼び出し禁止

```tsx
// BAD
if (cond) { const [x, setX] = useState(''); }  // 条件分岐内
<Button useData={useDataWithLogging} />         // props 渡し
return <Layout>{Article()}</Layout>;            // 直接呼び出し

// GOOD
return <Layout><Article /></Layout>;
```

### 純粋性のセマンティクス

「同じ出力」は `===` 参照一致ではなく**意味的同一性**。フックの返り値も入力の一部であり、`useState` を使っても純粋性は失われない。Strict Mode は開発環境で関数を2回呼び出し不純な計算を検出する。

---

## イベントハンドラ

```tsx
// BAD: レンダー時に即座に実行される
<button onClick={handleClick()}>

// GOOD: 関数参照を渡す
<button onClick={handleClick}>
<button onClick={() => handleClick(id)}>
```

- **命名**: コンポーネント内 `handle*`、props は `on*`
- **伝播停止**: `e.stopPropagation()` / **デフォルト防止**: `e.preventDefault()`
- イベントハンドラは純粋である必要はなく、副作用を行う主要な場所

---

## State

### 3分類

| 分類 | 説明 | 推奨ツール |
|------|------|-----------|
| **UI State** | 画面表示の一時的な状態（モーダル開閉等） | `useState` / `useReducer` |
| **App State** | アプリ全体で共有（ログインユーザー等） | Context / Zustand / Jotai |
| **Server State** | サーバーデータのキャッシュ | TanStack Query / SWR |

### ツール選定フロー

```
サーバーから取得したデータ？
  ├─ Yes → TanStack Query / SWR
  └─ No → 複数コンポーネントで共有？
            ├─ No → useState / useReducer
            └─ Yes → 更新頻度高い？
                      ├─ Yes → Zustand / Jotai
                      └─ No → Context
```

```tsx
// BAD: Server State を useState で管理
const [users, setUsers] = useState<User[]>([]);
useEffect(() => { fetchUsers().then(setUsers).catch(setError); }, []);

// GOOD: TanStack Query
const { data: users, isLoading, error } = useQuery({
  queryKey: ['users'], queryFn: fetchUsers,
});

// BAD: グローバルストアに全種類の state を混入（UI/Server/App の境界が崩壊）
// GOOD: Server State → TanStack Query / UI State → ローカル / App State → 最小限のストア
```

### Snapshot と Batch

set 関数を呼んでも**現在のレンダー内では値は変わらない**。クロージャもそのレンダー時点の値を保持する。

```tsx
// count = 0 の状態で実行
setCount(count + 1); // 0 + 1
setCount(count + 1); // 0 + 1（count はまだ 0）
// → 結果: 1（3 ではない）

// 更新用関数で前の値を基に計算
setCount(prev => prev + 1); // 3回呼べば +3
```

React はイベントハンドラ内の全 set をバッチ処理し、不要な再レンダーを防ぐ。

### State 設計

**5ステップ**: 視覚状態を列挙 → トリガを特定 → useState で表現 → 不要な state を削除 → ハンドラを接続

```tsx
// BAD: 矛盾しうる複数の boolean
const [isTyping, setIsTyping] = useState(false);
const [isSubmitting, setIsSubmitting] = useState(false);

// GOOD: 排他的な状態を単一 state に
const [status, setStatus] = useState<'typing' | 'submitting' | 'success'>('typing');
```

```tsx
// BAD: 計算可能な値を state に
const [count, setCount] = useState(list.length);

// GOOD: 既存 state から導出
const count = items.length;
```

---

## State 構造の原則

| 原則 | 説明 |
|------|------|
| 関連する state をグループ化 | 常に一緒に更新される変数は1つのオブジェクトに |
| 矛盾を避ける | 排他的な状態は単一 state に統合 |
| 冗長な state を避ける | props や既存 state から計算できる値は state にしない |
| 重複を避ける | 同じデータを複数の state に持たない |
| 深いネストを避ける | フラットな ID 参照に正規化する |

### props を state にコピーしない

```tsx
// BAD: 親の変更が反映されない
const [color, setColor] = useState(initialColor);

// GOOD: props を直接使用。初期値にする場合は initial/default プレフィックスで意図を明示
```

### 重複の排除

```tsx
// BAD: selectedItem が items の複製
const [selectedItem, setSelectedItem] = useState(items[0]);

// GOOD: ID のみ保持
const [selectedId, setSelectedId] = useState(items[0].id);
const selectedItem = items.find(item => item.id === selectedId);
```

---

## State の不変更新

### 配列メソッドの使い分け

| 操作 | 避ける（破壊的） | 使う（非破壊的） |
|------|-----------------|----------------|
| 追加 | `push`, `unshift` | `[...arr, item]` |
| 削除 | `pop`, `splice` | `filter`, `slice` |
| 置換 | `splice`, `arr[i]=` | `map` |
| ソート | `sort`, `reverse` | `[...arr].sort()` |

注意: `slice`（非破壊）と `splice`（破壊的）を混同しない。

### shallow copy の罠

```tsx
// BAD: 浅いコピーの内部オブジェクトをミューテーション
const newItems = [...items];
newItems[0].done = true; // 元の items[0] も変わる

// GOOD: map で新しいオブジェクトを作成
setItems(items.map(item =>
  item.id === targetId ? { ...item, done: true } : item
));
```

### ネストされたオブジェクトの更新

更新箇所からトップレベルまで全レベルでコピーが必要。深いネストが頻繁なら **Immer** を使う。

```tsx
// spread
setPerson({ ...person, artwork: { ...person.artwork, city: '新都市' } });

// Immer
updatePerson(draft => { draft.artwork.city = '新都市'; });
```

一般原則は @~/.claude/rules/robust-code.md（不変性）も参照。

---

## State の保持とリセット

React は state を **UIツリー内の位置**で管理する。

- **同じ位置 + 同じ型** → state 保持
- **同じ位置 + 異なる型** → state リセット（サブツリー全体が破棄）

### key によるリセット（インスタンスの交換）

key の変更は「state リセット」ではなく**インスタンスの交換**。配列の key と単一コンポーネントの key は同じ概念。

```tsx
// BAD: useEffect で props 変更時に state リセット
useEffect(() => { setName(user.name); setEmail(user.email); }, [user]);

// GOOD: key でインスタンスを交換（宣言的）
<UserProfileForm key={user.id} user={user} />
```

---

## useReducer

### useState との使い分け

| 観点 | useState | useReducer |
|------|---------|-----------|
| コードサイズ | 単純な更新に最適 | 複数の更新パターンに最適 |
| 可読性 | シンプルなら読みやすい | 更新ロジックを分離 |
| デバッグ | 更新箇所の特定が困難な場合あり | reducer で全更新を追跡 |
| テスト | コンポーネント依存 | 純粋関数として独立テスト |

### reducer のルール

1. **純粋関数** — 同じ入力 → 同じ出力、副作用なし
2. **1操作 = 1アクション** — 5つの `set_field` ではなく `reset_form`
3. **state をミューテーションしない**（Immer 使用時は `useImmerReducer` で簡潔に書ける）

### State Reducer パターン

コンポーネントの state 遷移を外部からカスタマイズ可能にする（Kent C. Dodds 提唱）。

```tsx
type StateReducer<S, A> = (state: S, action: A, defaultChanges: S) => S;

// コンポーネント内部
const customReducer = (state, action) => {
  const defaultChanges = counterReducer(state, action);
  return stateReducer(state, action, defaultChanges); // 外部から上書き可能
};

// 使用側: 偶数のみ許可
<Counter stateReducer={(state, action, changes) =>
  changes.count % 2 !== 0 ? { count: changes.count + 1 } : changes
} />
```

Inversion of Control: 消費者にロジック拡張を委譲しつつ、コア機能を保護。

---

## Context

### 使う前に検討

1. **まず props** — 明示的なデータフローが依存関係を明確に
2. **children を活用** — 中間コンポーネントのレイヤーを減らす
3. それでも不十分なら Context

### Reducer + Context のスケーリング

state（読み取り）と dispatch（書き込み）を分離した Context で、dispatch のみ使うコンポーネントの不要な再レンダーを防ぐ。

```tsx
const TasksContext = createContext<Task[]>([]);
const TasksDispatchContext = createContext<Dispatch<TaskAction>>(() => {});

export function TasksProvider({ children }: { children: ReactNode }) {
  const [tasks, dispatch] = useReducer(tasksReducer, initialTasks);
  return (
    <TasksContext value={tasks}>
      <TasksDispatchContext value={dispatch}>
        {children}
      </TasksDispatchContext>
    </TasksContext>
  );
}

// カスタムフックで簡潔に消費
export const useTasks = () => useContext(TasksContext);
export const useTasksDispatch = () => useContext(TasksDispatchContext);
```

---

## Ref

### ref vs state

| | ref | state |
|---|---|---|
| 変更時の再レンダー | なし | あり |
| ミュータビリティ | `current` を直接変更 | set 関数経由 |
| レンダー中の読み書き | すべきでない | 読み取り可能 |

### 用途（React 外部との連携）

- タイムアウト/インターバル ID の保存
- DOM 要素へのアクセス（フォーカス、スクロール、測定）
- JSX 計算に不要なオブジェクトの保持

### アンチパターン

```tsx
// BAD: レンダー中に ref を読み書き
countRef.current++;
return <p>{countRef.current}</p>;
```

### DOM ref の転送

```tsx
function MyInput({ ref, ...props }: ComponentProps<'input'>) {
  return <input ref={ref} {...props} />;
}
```

`useImperativeHandle` で公開操作を制限可能。React が管理する DOM の直接変更は**非破壊的操作**（フォーカス、スクロール）に限定する。

---

## useEffect

### 本質: 外部システムとの同期

useEffect は「同期の開始と停止」。マウント/アンマウントのライフサイクルではない。

```tsx
useEffect(() => {
  const conn = createConnection(roomId);
  conn.connect();
  return () => conn.disconnect(); // クリーンアップ必須
}, [roomId]);
```

**クリーンアップ関数のない useEffect は原則不適格。**

### 依存配列のルール

- エフェクトが読み取る**すべてのリアクティブな値**を含める
- 「選ぶもの」ではなく「コードが決めるもの」
- **リンター抑制は禁止** — コードを修正する

### useEffect が不要なケース

| ケース | 代替 |
|--------|------|
| 派生値の計算 | レンダー中に直接計算 / `useMemo` |
| ユーザーイベントへの応答 | イベントハンドラ |
| props 変更時の state リセット | `key` でインスタンス交換 |
| 外部ストアの購読 | `useSyncExternalStore` |
| 値の変化への反応 | イベントハンドラ |

### データフェッチ

useEffect でのフェッチはレース条件・ウォーターフォール・責務肥大化の問題がある。TanStack Query / SWR を推奨。

```tsx
// 許容: ignore フラグでレース条件を防ぐ
useEffect(() => {
  let ignore = false;
  fetchData(query).then(data => { if (!ignore) setData(data); });
  return () => { ignore = true; };
}, [query]);
```

### 適用判定表

| 用途 | 適切か |
|------|--------|
| イベントリスナー登録/解除 | **適切** |
| WebSocket 接続管理 | **適切** |
| データフェッチ | **許容**（ライブラリ推奨） |
| 派生値の計算 | **不適切** |
| トラッキング/分析 | **不適切** |

### 依存値を減らすパターン

| 手法 | 場面 |
|------|------|
| イベントハンドラへ移動 | 特定操作への応答 |
| エフェクトの分割 | 無関係な同期プロセスが混在 |
| 更新用関数 | `setState(prev => ...)` |
| useEffectEvent（実験的） | 値を読みたいが変更に反応したくない |

オブジェクト/関数はレンダーごとに新しい参照が作成される。**エフェクト内部でオブジェクトを作成**し、依存配列にはプリミティブ値のみ含める。

---

## カスタムフック

- `use` + 大文字で始まる名前。フックを呼び出さない関数には `use` を付けない
- **ロジックの共有であり state の共有ではない** — 各呼び出しは独立した state を持つ
- `useMount`, `useEffectOnce` 等の**ライフサイクルラッパーは避ける**（依存配列の検証がスキップされる）

---

## 再レンダリング最適化

**設計 > memo** の原則。メモ化は最終手段。

### 選択基準

| パターン | 用途 | 手法 |
|---------|------|------|
| **1. コロケーション** | state が特定部分に限定 | state を使うコンポーネントに移動 |
| **2. コンポジション** | state 共有 + 重い子の分離 | `children` / props として渡す |
| **3. React.memo** | 上記で解決不可 | props 変更時のみ再レンダー |

### コンポジションのメカニズム

親から渡された `children` は state 変更時でも再生成されないため、**参照同一性が保持**されコミットがスキップされる。

```tsx
function ColorPicker({ children }: { children: ReactNode }) {
  const [color, setColor] = useState('red');
  return (
    <div style={{ color }}>
      <input value={color} onChange={e => setColor(e.target.value)} />
      {children} {/* 再レンダーされない */}
    </div>
  );
}
```
