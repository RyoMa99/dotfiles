# React 設計原則

React 公式ドキュメントに基づく設計原則とルール。

関連: @~/.claude/rules/web-frontend.md（コンポーネント設計、状態管理、ディレクトリ構成）
関連: @~/.claude/rules/robust-code.md（型による予防的設計）
関連: @~/.claude/rules/testing.md（フロントエンドテストセクション）

---

## コンポーネントの基本

### 定義ルール

- コンポーネントは**大文字で始まる関数**として定義する
- 小文字はHTML要素として解釈される（`<profile>` = HTML、`<Profile />` = React）
- 複数行のJSXは `()` で囲んで return する

```tsx
// GOOD: 大文字で始まる関数コンポーネント
function ProfileCard({ user }: Props) {
  return (
    <div>
      <h2>{user.name}</h2>
    </div>
  );
}
```

### コンポーネント定義のネスト禁止

コンポーネント内部で別のコンポーネントを定義しない。パフォーマンス低下とバグの原因になる。

```tsx
// BAD: ネストされたコンポーネント定義
function Gallery() {
  function Photo() { // レンダーごとに再定義される
    return <img src="..." />;
  }
  return <Photo />;
}

// GOOD: トップレベルで定義し、props で連携
function Photo({ src }: { src: string }) {
  return <img src={src} />;
}

function Gallery() {
  return <Photo src="..." />;
}
```

---

## JSX のルール

### 3つの基本ルール

1. **単一のルート要素を返す** — 複数要素は Fragment `<>...</>` で囲む
2. **すべてのタグを閉じる** — `<img />`, `<br />`, `<input />`
3. **属性はキャメルケース** — `class` → `className`, `stroke-width` → `strokeWidth`

```tsx
// GOOD: Fragment で複数要素をラップ
function UserInfo() {
  return (
    <>
      <h1>タイトル</h1>
      <p>説明文</p>
    </>
  );
}
```

### 例外

- `aria-*` と `data-*` 属性はハイフン区切りのまま使用する

```tsx
<button aria-label="閉じる" data-testid="close-btn">×</button>
```

---

## Props

### 基本原則

- props は**読み取り専用（イミュータブル）**。コンポーネント内で変更しない
- 分割代入で受け取り、デフォルト値を設定できる
- ネストした JSX は `children` として自動的に渡される

```tsx
// 分割代入 + デフォルト値
function Avatar({ person, size = 100 }: AvatarProps) {
  return <img width={size} src={person.imageUrl} alt={person.name} />;
}

// children の活用
function Card({ children }: { children: ReactNode }) {
  return <div className="card">{children}</div>;
}

// 使用側
<Card>
  <Avatar person={user} />
</Card>
```

### デフォルト値の挙動

- `undefined` の場合のみデフォルト値が適用される
- `null` や `0` ではデフォルト値は適用されない

### スプレッド構文の注意

```tsx
// 慎重に使用。多用はコンポーネント分割のサイン
function Profile(props: ProfileProps) {
  return <Avatar {...props} />;
}
```

---

## 条件付きレンダー

### パターンの使い分け

| パターン | 用途 |
|---------|------|
| `if/else` + return | 分岐が大きい・JSX構造が異なる |
| 三項演算子 `? :` | true/false 両方で異なるコンテンツ |
| `&&` | 条件が true のときだけ表示 |
| 変数への条件付き代入 | 複雑なロジック |

### `&&` の落とし穴

左辺が `0` の場合、`0` 自体が画面に表示される。必ず真偽値に変換する。

```tsx
// BAD: messageCount が 0 だと「0」が表示される
{messageCount && <p>新着メッセージ</p>}

// GOOD: 真偽値に変換
{messageCount > 0 && <p>新着メッセージ</p>}
```

### 何も表示しない場合

`null` を返すことは可能だが、親コンポーネント側で条件分岐する方が慣例的。

```tsx
// 可能だが一般的ではない
function Item({ name, isPacked }: Props) {
  if (isPacked) return null;
  return <li>{name}</li>;
}

// 慣例的: 親側で制御
{!isPacked && <Item name={name} />}
```

---

## リストのレンダー

### 基本パターン

```tsx
// filter + map の組み合わせ
function ActiveUserList({ users }: { users: User[] }) {
  return (
    <ul>
      {users
        .filter(user => user.isActive)
        .map(user => (
          <li key={user.id}>{user.name}</li>
        ))}
    </ul>
  );
}
```

### key のルール

| ルール | 理由 |
|--------|------|
| **必須** | React がコンポーネントの同一性を追跡するため |
| **兄弟間で一意** | 異なる配列間では同じ key を使ってよい |
| **変更不可** | key が変わると state がリセットされる |

### key のアンチパターン

```tsx
// BAD: インデックスを key にする（挿入・削除・並び替えでバグ）
{items.map((item, index) => <Item key={index} {...item} />)}

// BAD: ランダム値を key にする（毎回再生成で state 消失）
{items.map(item => <Item key={Math.random()} {...item} />)}

// GOOD: データ固有の一意な ID を使用
{items.map(item => <Item key={item.id} {...item} />)}
```

### アロー関数の return

`=> {` 形式ではブロックボディとなり、明示的な `return` が必要。

```tsx
// BAD: return がないため undefined を返す
{items.map(item => { <li>{item.name}</li> })}

// GOOD: 明示的な return
{items.map(item => { return <li key={item.id}>{item.name}</li>; })}

// GOOD: 簡潔ボディ（return 不要）
{items.map(item => <li key={item.id}>{item.name}</li>)}
```

---

## コンポーネントの純粋性と React のルール

### 純粋性の3原則

1. **冪等性** — 同じ入力（props, state, context）で常に同じ JSX を返す
2. **レンダー中の副作用禁止** — 副作用はイベントハンドラまたはエフェクト内で実行
3. **ローカル値以外の変更禁止** — 外部から参照される値をレンダー中に書き換えない

```tsx
// BAD: 外部変数のミューテーション
let guestCount = 0;
function Cup() {
  guestCount++; // レンダーごとに変わる = 不純
  return <h2>Guest #{guestCount}</h2>;
}

// GOOD: props から受け取る
function Cup({ guestNumber }: { guestNumber: number }) {
  return <h2>Guest #{guestNumber}</h2>;
}
```

### レンダー中に禁止される操作

- `new Date()`, `Math.random()` 等の非冪等な関数呼び出し
- グローバル変数の書き換え
- DOM の直接操作
- API 呼び出し・ネットワークリクエスト

### ローカルミューテーションは許容

レンダー中にその場で作成した変数・オブジェクトの変更は問題ない。

```tsx
// OK: レンダー中に作成したローカル配列への push
function CupList() {
  const cups = [];
  for (let i = 1; i <= 12; i++) {
    cups.push(<Cup key={i} guestNumber={i} />);
  }
  return cups;
}
```

### 不変性ルール

| 対象 | ルール |
|------|--------|
| props | 直接書き換え禁止。新しいオブジェクトを作成 |
| state | set 関数経由でのみ更新 |
| フックの引数・戻り値 | 書き換え禁止（メモ化が壊れる） |
| JSX に渡した値 | 渡した後は書き換えない |

### 副作用の配置

| 配置場所 | 用途 | 優先度 |
|---------|------|--------|
| **イベントハンドラ** | ユーザー操作に応じた処理（API呼び出し、state更新） | 第一選択 |
| **`useEffect`** | レンダー後に実行すべき副作用（DOM操作、購読） | 最終手段 |

レンダーロジック内に副作用を書かない。

### フックのルール

1. **トップレベルでのみ呼び出す** — 条件分岐、ループ、ネスト関数、try/catch 内での呼び出しは禁止
2. **React 関数内でのみ呼び出す** — 関数コンポーネントまたはカスタムフック内
3. **通常の値として扱わない** — props として渡す、変数に格納して動的に呼び出す等は禁止

```tsx
// BAD: 条件分岐内でフックを呼び出す
if (isLoggedIn) {
  const [name, setName] = useState('');
}

// BAD: フックを props として渡す
<Button useData={useDataWithLogging} />

// BAD: コンポーネント関数を直接呼び出す
return <Layout>{Article()}</Layout>;

// GOOD: JSX でコンポーネントを使用
return <Layout><Article /></Layout>;
```

### 純粋性のセマンティクス（uhyo）

「同じ出力」とは `===` による参照一致ではなく、**意味的に同じ**かどうかで判断する。JSX は「React ランタイムへの指示書」であり、同じ指示を毎回返すなら純粋と見なされる。

フックの返り値も入力の一部。`useState` を使っても純粋性は失われない。同じ props + 同じフック状態 → 同じ出力が保証される。

副作用があっても**冪等性**を満たせばコンポーネントとして許容される場合がある。例えば `fetchNote(id)` がキャッシュを使い実際のリクエストを1回だけ実行する場合、コンポーネントは冪等。ただしこれは `use()` RFC のようなデータフェッチの新パラダイムに関する議論であり、通常のコンポーネントでは依然としてレンダー中の副作用を避けるべき。

### Strict Mode

開発環境で各コンポーネント関数を2回呼び出し、不純な計算を検出する。純粋関数なら2回呼んでも結果は同じ。

---

## UIツリーの理解

### レンダーツリー

- React アプリはコンポーネントのツリー構造で表現される
- 条件付きレンダーにより、レンダーごとにツリー構造が変わりうる
- **トップレベルコンポーネント**: ルートに近く、配下全体のパフォーマンスに影響
- **リーフコンポーネント**: 子を持たない末端。頻繁に再レンダーされる

### モジュール依存ツリー

- import 関係のマッピング。バンドルサイズ最適化に利用される
- コンポーネント以外のモジュール（ユーティリティ、定数）も含まれる

---

## イベントハンドラ

### 定義と渡し方

イベントハンドラはコンポーネント内で定義し、JSX に**関数への参照**を渡す。呼び出し結果を渡さない。

```tsx
// BAD: レンダー時に即座に実行される
<button onClick={handleClick()}>クリック</button>

// GOOD: 関数への参照を渡す
<button onClick={handleClick}>クリック</button>

// GOOD: インラインで定義
<button onClick={() => handleClick(id)}>クリック</button>
```

### 命名規則

- コンポーネント内のハンドラ: `handle` + イベント名（`handleClick`, `handleSubmit`）
- Props として渡す場合: `on` + 大文字（`onClick`, `onPlayMovie`）

### イベント伝播（バブリング）

イベントは子→親へ上方向に伝播する。`e.stopPropagation()` で停止できる。

```tsx
<button onClick={e => {
  e.stopPropagation(); // 親への伝播を停止
  onClick();
}}>
```

### デフォルト動作の防止

フォーム送信などブラウザのデフォルト動作を防ぐには `e.preventDefault()` を使う。

```tsx
<form onSubmit={e => {
  e.preventDefault(); // ページリロードを防止
  submitData();
}}>
```

### 副作用の許可

イベントハンドラは純粋である必要はない。state 変更や API 呼び出しなどの副作用を行う主要な場所。

---

## State

### useState の基本

```tsx
const [count, setCount] = useState(0);
```

- 第1要素: 現在の state 値
- 第2要素: 更新関数（set 関数）
- 引数: 初期値

### ローカル変数との違い

| | ローカル変数 | state |
|---|---|---|
| レンダー間の保持 | されない | される |
| 変更時の再レンダー | されない | トリガされる |

### フックのルール

- `use` で始まる関数はフックであり、**コンポーネントのトップレベルでのみ**呼び出せる
- 条件分岐、ループ、ネストされた関数内での呼び出しは禁止

```tsx
// BAD: 条件分岐内でフックを呼び出す
if (isLoggedIn) {
  const [name, setName] = useState('');
}

// GOOD: トップレベルで呼び出す
const [name, setName] = useState('');
```

### state の独立性

同じコンポーネントを複数レンダーした場合、各インスタンスは完全に独立した state を持つ。親は子の state を知ることも変更することもできない。

---

## レンダーとコミット

### 3つのステップ

1. **トリガ** — 初回レンダー（`createRoot` + `render`）または state の更新
2. **レンダー** — React がコンポーネント関数を呼び出す（再帰的に子も呼び出す）
3. **コミット** — 差分のあるDOMノードのみを更新する

### 重要な原則

- レンダーは**純粋な計算**であるべき（副作用なし）
- React はレンダー間で差分がある場合にのみ DOM を変更する
- 同じ入力（props, state, context）→ 同じ出力（JSX）

---

## State はスナップショット

### 核心概念

set 関数を呼び出しても、**現在のレンダー内では state の値は変わらない**。各レンダーは state の固定スナップショットを持つ。

```tsx
// count = 0 の状態で実行
function handleClick() {
  setCount(count + 1); // 0 + 1 = 1 をセット
  setCount(count + 1); // 0 + 1 = 1 をセット（count はまだ 0）
  setCount(count + 1); // 0 + 1 = 1 をセット（count はまだ 0）
  // 結果: 次のレンダーで count = 1（3 ではない）
}
```

### 非同期処理でも同じ

タイマーやイベントハンドラのクロージャは、**そのレンダー時点の state 値**を保持する。

```tsx
function handleClick() {
  setCount(count + 1);
  setTimeout(() => {
    alert(count); // セット前の値が表示される（スナップショット）
  }, 3000);
}
```

---

## State 更新のキューイング

### バッチ処理

React はイベントハンドラ内のすべてのコードが実行されるまで state の更新処理を待機する。これにより不要な再レンダーを防ぐ。

### 更新用関数（Updater Function）

同一レンダー内で state を複数回更新する場合、**更新用関数**を渡す。

```tsx
// BAD: 3回呼んでも +1 しかされない（スナップショットの値を使用）
setCount(count + 1);
setCount(count + 1);
setCount(count + 1);

// GOOD: 更新用関数で前の値を基に計算（+3 される）
setCount(prev => prev + 1);
setCount(prev => prev + 1);
setCount(prev => prev + 1);
```

### 更新用関数のルール

- **純粋関数**であること（値の計算と return のみ、副作用なし）
- 命名慣例: state 変数名の頭文字（`setCount(c => c + 1)`）またはフルネーム（`setCount(prevCount => prevCount + 1)`）

---

## State 内オブジェクトの更新

### イミュータブルに扱う

state 内のオブジェクトは直接変更せず、新しいオブジェクトを作成して置き換える。

```tsx
// BAD: ミューテーション（React が変更を検知できない）
person.name = '新しい名前';
setPerson(person);

// GOOD: 新しいオブジェクトを作成
setPerson({ ...person, name: '新しい名前' });
```

### ネストされたオブジェクトの更新

更新箇所からトップレベルまですべてのレベルでコピーを作成する。

```tsx
setPerson({
  ...person,
  artwork: {
    ...person.artwork,
    city: '新しい都市',
  },
});
```

### ミューテーションが非推奨な理由

- React が変更を検知できず再レンダーされない
- デバッグが困難になる
- React の最適化（memo 等）が機能しなくなる
- undo/redo 等の機能実装が困難になる

### Immer の活用

深いネストの更新が頻繁な場合、Immer でミューテーション風の簡潔な記述が可能。

```tsx
import { useImmer } from 'use-immer';

const [person, updatePerson] = useImmer(initialPerson);

updatePerson(draft => {
  draft.artwork.city = '新しい都市'; // ミューテーション風だが安全
});
```

---

## State 内配列の更新

### メソッドの使い分け

| 操作 | 避ける（ミューテーション） | 使う（新しい配列を返す） |
|------|------------------------|----------------------|
| 追加 | `push`, `unshift` | `[...arr, item]`, `concat` |
| 削除 | `pop`, `shift`, `splice` | `filter`, `slice` |
| 置換 | `splice`, `arr[i] = x` | `map` |
| ソート | `reverse`, `sort` | コピーしてからソート |

### 基本パターン

```tsx
// 追加
setItems([...items, newItem]);

// 削除
setItems(items.filter(item => item.id !== targetId));

// 置換
setItems(items.map(item =>
  item.id === targetId ? { ...item, done: true } : item
));

// ソート（コピーしてから）
const sorted = [...items].sort((a, b) => a.name.localeCompare(b.name));
setItems(sorted);
```

### 配列内オブジェクトの更新

`map` で新しいオブジェクトを作成する。配列のコピーは浅いため、内部オブジェクトを直接変更するとミューテーションになる。

```tsx
// BAD: 浅いコピーの内部オブジェクトをミューテーション
const newItems = [...items];
newItems[0].done = true; // 元の items[0] も変わる

// GOOD: map で新しいオブジェクトを作成
setItems(items.map(item =>
  item.id === targetId ? { ...item, done: true } : item
));
```

### slice と splice の違い

- `slice`: 配列の一部をコピーして返す（**非破壊的** — state で安全に使える）
- `splice`: 配列を直接変更する（**破壊的** — state で使わない）

---

## 宣言的 UI と State 設計

### 宣言的 UI の考え方

命令的UI（「どのように」更新するか）ではなく、宣言的UI（「何を」表示したいか）で考える。React は state に基づいて UI を自動更新する。

### State 設計の5ステップ

1. **視覚状態を列挙** — コンポーネントが取りうるすべての状態を洗い出す（Empty, Typing, Submitting, Success, Error 等）
2. **トリガを特定** — 人間の入力（クリック、入力）とコンピュータの入力（API応答）
3. **`useState` で表現** — 最初は多めに定義してよい
4. **不要な state を削除** — 矛盾・冗長・重複を排除
5. **イベントハンドラを接続** — state を更新して操作に反応

### 不要な state の判定

```tsx
// BAD: 矛盾しうる複数の boolean
const [isTyping, setIsTyping] = useState(false);
const [isSubmitting, setIsSubmitting] = useState(false);
// → isTyping と isSubmitting が同時に true になりうる

// GOOD: 単一の status で排他的な状態を表現
const [status, setStatus] = useState<'typing' | 'submitting' | 'success'>('typing');
```

```tsx
// BAD: 計算で導出できる値を state にする
const [items, setItems] = useState(list);
const [count, setCount] = useState(list.length); // items.length で十分

// GOOD: 既存の state から計算
const count = items.length;
```

---

## State 構造の原則

### 5つの原則

| 原則 | 説明 |
|------|------|
| **関連する state をグループ化** | 常に一緒に更新される変数は1つのオブジェクトにまとめる |
| **矛盾を避ける** | 同時に true になれない状態は単一の state に統合 |
| **冗長な state を避ける** | props や既存 state から計算できる値を state にしない |
| **重複を避ける** | 同じデータを複数の state に持たない |
| **深いネストを避ける** | フラットな構造（ID参照）に正規化する |

### props を state にコピーしない

```tsx
// BAD: props の変更が反映されない
function Message({ initialColor }: { initialColor: string }) {
  const [color, setColor] = useState(initialColor);
  // 親が initialColor を変更しても color は更新されない
}

// GOOD: props を直接使用
function Message({ color }: { color: string }) {
  return <p style={{ color }}>{/* ... */}</p>;
}
```

props を state の初期値にする場合は `initial` や `default` プレフィックスで意図を明示する。

### 重複の排除

```tsx
// BAD: 同じオブジェクトが items と selectedItem に重複
const [items, setItems] = useState(initialItems);
const [selectedItem, setSelectedItem] = useState(items[0]);

// GOOD: ID のみを保持し、レンダー時に検索
const [items, setItems] = useState(initialItems);
const [selectedId, setSelectedId] = useState(items[0].id);
const selectedItem = items.find(item => item.id === selectedId);
```

### 深いネストの正規化

```tsx
// BAD: 深いネスト（更新時に全レベルのコピーが必要）
const [tree, setTree] = useState({
  id: 0,
  children: [{ id: 1, children: [{ id: 2, children: [] }] }],
});

// GOOD: フラットな ID 参照（DB のテーブル設計と同じ）
const [nodes, setNodes] = useState({
  0: { id: 0, childIds: [1] },
  1: { id: 1, childIds: [2] },
  2: { id: 2, childIds: [] },
});
```

---

## State の保持とリセット

### 保持の条件

React は state を **UIツリー内の位置**に基づいて管理する。

- **同じ位置 + 同じコンポーネント型** → state は保持される
- **同じ位置 + 異なるコンポーネント型** → state はリセットされる（サブツリー全体が破棄）

```tsx
// isPlayerA を切り替えても、同じ位置の Counter なので state は保持される
{isPlayerA ? <Counter person="A" /> : <Counter person="B" />}
```

### key で state をリセットする

同じ位置の同じコンポーネントで state をリセットしたい場合、**key** を変更する。

```tsx
// key が変わるとコンポーネントが再作成され、state がリセットされる
<ChatInput key={selectedUserId} />
```

これはリスト以外でも有効。フォームの切り替え、タブの切り替え等で活用する。

### key はインスタンスの交換（uhyo）

key の変更を「state のリセット」ではなく、**インスタンスの交換**として捉える。

```tsx
// 「key が alice の UserProfileForm が消えて、
//  key が bob の新しい UserProfileForm が現れた」と考える
<UserProfileForm key={user.id} user={user} />

// 以下と意味的に等価:
{user.id === "alice" && <UserProfileForm user={user} />}
{user.id === "bob" && <UserProfileForm user={user} />}
```

配列の `key` と単一コンポーネントの `key` は同じ概念。「複数のレンダリング間で一貫したインスタンスの識別を可能にする」ための仕組みであり、宣言的 UI の枠組みを補強する正当な手法。

```tsx
// BAD: useEffect で props 変更時に state をリセット
useEffect(() => {
  setName(user.name);
  setEmail(user.email);
}, [user]);

// GOOD: key でインスタンスを交換（宣言的）
<UserProfileForm key={user.id} user={user} />
```

### コンポーネント定義のネストが危険な理由（再掲）

内部で定義するとレンダーごとに新しい関数が作成され、React が異なるコンポーネントと認識して毎回 state がリセットされる。

---

## useReducer

### useState との使い分け

| 観点 | useState | useReducer |
|------|---------|-----------|
| コードサイズ | 単純な更新に最適 | 複数の更新パターンに最適 |
| 可読性 | シンプルなら読みやすい | 更新ロジックを分離できる |
| デバッグ | 更新箇所の特定が難しい場合あり | すべての更新を reducer で追跡可能 |
| テスト | コンポーネント依存 | 純粋関数として独立テスト可能 |

### 基本構造

```tsx
const [state, dispatch] = useReducer(reducer, initialState);

// アクションをディスパッチ
dispatch({ type: 'added', id: nextId++, text });

// reducer 関数（純粋関数）
function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'added':
      return [...state, { id: action.id, text: action.text }];
    case 'deleted':
      return state.filter(item => item.id !== action.id);
    default:
      throw new Error(`Unknown action: ${action.type}`);
  }
}
```

### reducer のルール

1. **純粋関数**であること — 同じ入力 → 同じ出力。副作用なし
2. **1つのユーザー操作 = 1つのアクション** — 5つの `set_field` ではなく1つの `reset_form`
3. **state をミューテーションしない** — スプレッド / `map` / `filter` で新しいオブジェクトを返す

### Immer との組み合わせ

```tsx
import { useImmerReducer } from 'use-immer';

function reducer(draft: State, action: Action) {
  switch (action.type) {
    case 'added':
      draft.push({ id: action.id, text: action.text }); // ミューテーション風
      break;
  }
}
```

### State Reducer パターン

コンポーネントの state 遷移ロジックを外部からカスタマイズ可能にするパターン（Kent C. Dodds 提唱）。Compound Components と組み合わせると、柔軟で拡張性の高いコンポーネント設計が実現する。

**仕組み**: コンポーネント内部の reducer を props 経由で上書き・拡張できるようにする。消費者はデフォルトの state 遷移を参照しつつ、必要な部分だけ変更する。

```tsx
type StateReducer<S, A> = (state: S, action: A, defaultChanges: S) => S;

interface CounterProps {
  initialCount?: number;
  step?: number;
  stateReducer?: StateReducer<CounterState, CounterAction>;
}

function Counter({ initialCount = 0, step = 1, stateReducer = (_, __, changes) => changes }: CounterProps) {
  const customReducer = (state: CounterState, action: CounterAction): CounterState => {
    const defaultChanges = counterReducer(state, action); // デフォルトの遷移を計算
    return stateReducer(state, action, defaultChanges);    // 外部から上書き可能
  };

  const [state, dispatch] = useReducer(customReducer, { count: initialCount });
  // ...
}

// 使用側: 偶数のみを許可するカスタムロジック
<Counter
  stateReducer={(state, action, changes) => {
    if (changes.count % 2 !== 0) {
      return { count: changes.count + 1 }; // 奇数を次の偶数に補正
    }
    return changes; // デフォルトをそのまま採用
  }}
/>
```

**利点**:
- コンポーネントの内部ロジックを変更せずに振る舞いを拡張
- デフォルトの遷移（`defaultChanges`）を参照できるため、差分のみの記述で済む
- Inversion of Control: 制御を消費者に委譲しつつ、コア機能を保護

---

## Context

### props のバケツリレー問題

中間コンポーネントが使わない props を受け取って下に渡すだけの状態。Context で解決する。

### 3ステップ

```tsx
// 1. Context を作成
const ThemeContext = createContext<Theme>('light');

// 2. Provider で値を供給
function App() {
  const [theme, setTheme] = useState<Theme>('light');
  return (
    <ThemeContext value={theme}>
      <Page />
    </ThemeContext>
  );
}

// 3. useContext で消費
function Button() {
  const theme = useContext(ThemeContext);
  return <button className={theme}>ボタン</button>;
}
```

### Context を使う前に検討すること

1. **まず props を試す** — 明示的なデータフローは依存関係を明確にする
2. **children を活用** — 中間コンポーネントに `children` を渡してレイヤーを減らす
3. それでも解決しない場合に Context を導入する

### 適した用途

- テーマ（ダーク/ライト）
- ログインユーザー情報
- ルーティング
- 複雑な状態管理（reducer との組み合わせ）

---

## Reducer + Context のスケーリング

### Provider コンポーネントへの抽出

reducer と context を1つのコンポーネントにカプセル化する。

```tsx
// TasksProvider.tsx
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

// カスタムフックで消費を簡潔に
export function useTasks() {
  return useContext(TasksContext);
}

export function useTasksDispatch() {
  return useContext(TasksDispatchContext);
}
```

### 使用側

```tsx
// App.tsx — Provider でラップ
function App() {
  return (
    <TasksProvider>
      <TaskList />
      <AddTask />
    </TasksProvider>
  );
}

// TaskList.tsx — カスタムフックで消費
function TaskList() {
  const tasks = useTasks();
  const dispatch = useTasksDispatch();
  // ...
}
```

state（読み取り）と dispatch（書き込み）を分離することで、dispatch のみを使うコンポーネントが state 変更時に再レンダーされることを防げる。

---

## コンポーネント設計パターン

### Container / Presentational パターン

ロジックと UI を分離し、関心の分離を図るパターン。Hooks 時代でも有効。

| | Container | Presentational |
|---|---|---|
| 責務 | ロジック（データ取得、state 管理） | UI 表現 |
| 状態 | あり | 原則なし |
| データ源 | API・hooks | props のみ |
| テスト | ロジック検証 | UI 検証 |

```tsx
// ロジック専用 hooks
function useTodos() {
  const [todos, setTodos] = useState<Todo[]>([]);
  useEffect(() => { fetchTodos().then(setTodos); }, []);
  return { todos };
}

// Container: hooks と UI の橋渡し
function TodoContainer() {
  const { todos } = useTodos();
  return <TodoList todos={todos} />;
}

// Presentational: props のみ依存（純粋）
function TodoList({ todos }: { todos: Todo[] }) {
  return (
    <ul>
      {todos.map(todo => <li key={todo.id}>{todo.title}</li>)}
    </ul>
  );
}
```

hooks・Container・Presentational の3層を疎結合に保つことで、ロジック変更時に UI が影響を受けない。

### Presentational のルール

- props のみからデータを受け取る（グローバル状態を直接参照しない）
- 外部 API を直接呼び出さない
- Redux / Zustand 等の状態管理ライブラリに直接依存しない

### Compound Components パターン

HTML の `<select>/<option>` のように、親子関係を持つコンポーネント群で構成する。Context で暗黙的にデータを共有し、props のバケツリレーを回避する。

```tsx
// 親: 状態を一元管理し Context で供給
function Tabs({ children, defaultValue }: TabsProps) {
  const [activeTab, setActiveTab] = useState(defaultValue);
  return (
    <TabsContext value={{ activeTab, setActiveTab }}>
      <div role="tablist">{children}</div>
    </TabsContext>
  );
}

// 子: Context から値を取得
function Tab({ value, children }: TabProps) {
  const { activeTab, setActiveTab } = useContext(TabsContext);
  return (
    <button role="tab" aria-selected={activeTab === value} onClick={() => setActiveTab(value)}>
      {children}
    </button>
  );
}

function TabPanel({ value, children }: TabPanelProps) {
  const { activeTab } = useContext(TabsContext);
  if (activeTab !== value) return null;
  return <div role="tabpanel">{children}</div>;
}

// 使用側: レイアウトを自由に構成
<Tabs defaultValue="a">
  <Tab value="a">タブA</Tab>
  <Tab value="b">タブB</Tab>
  <TabPanel value="a">コンテンツA</TabPanel>
  <TabPanel value="b">コンテンツB</TabPanel>
</Tabs>
```

**利点:**
- 使用者がレイアウトを自由に決定できる
- 新要素（TabIcon, TabBadge 等）の追加が既存コードに影響しない
- 各部品が単一責務で単体テストしやすい

### Render Hooks パターン

関連する state と UI をカスタムフックにカプセル化する。

```tsx
function useModal() {
  const [isOpen, setIsOpen] = useState(false);
  const renderModal = (children: ReactNode) => (
    <Modal isOpen={isOpen} onClose={() => setIsOpen(false)}>
      {children}
    </Modal>
  );
  return { onOpen: () => setIsOpen(true), renderModal };
}

// 使用側
function App() {
  const { onOpen, renderModal } = useModal();
  return (
    <>
      <button onClick={onOpen}>開く</button>
      {renderModal(<p>モーダルの中身</p>)}
    </>
  );
}
```

state 管理と表示ロジックが1箇所にまとまり、コンポーネントの見通しが良くなる。

### 制御/非制御コンポーネント

| | 制御 | 非制御 |
|---|---|---|
| 状態管理 | React（useState 等） | DOM 自身 |
| 値の取得 | state から | ref / FormData から |
| React Hook Form | `Controller` / `useController` が必要 | `register()` で直接接続 |

Atoms レベルの UI コンポーネントでは、DOM 要素のネイティブな状態を活用してスタイリングする。CSS 疑似クラス（`:checked`, `:placeholder-shown`）と疑似要素で状態を反映することで、制御・非制御の双方に対応できる。

### Props の TypeScript 設計

#### ComponentProps パターン

HTML 要素として振る舞うコンポーネントは `React.ComponentProps` で全属性を継承する。

```tsx
// 基本: HTML 要素の全属性を自動継承
type InputProps = React.ComponentProps<'input'>;

// 拡張: 独自 props + HTML 属性
type TextFieldProps = React.ComponentProps<'input'> & {
  label: string;
  error?: string;
};

// 除外: 特定 props を型レベルで禁止
type StyledInputProps = Omit<React.ComponentProps<'input'>, 'className'> & {
  variant: 'outlined' | 'filled';
};
```

#### Rest Spread で転送

```tsx
function TextField({ label, error, ...inputProps }: TextFieldProps) {
  return (
    <div>
      <label>{label}</label>
      <input {...inputProps} />
      {error && <span>{error}</span>}
    </div>
  );
}
```

`onFocus`, `aria-*`, `data-testid` 等を個別に props 定義する必要がなくなる。

#### Union 型で選択肢を制約

```tsx
// switch の網羅性を TypeScript が検証
type Status = 'loading' | 'success' | 'error' | 'idle';
```

---

## Ref

### useRef の基本

```tsx
const ref = useRef(initialValue);
// ref.current で読み書き
```

### ref と state の違い

| | ref | state |
|---|---|---|
| 変更時の再レンダー | なし | あり |
| ミュータビリティ | `ref.current` を直接変更 | set 関数経由 |
| レンダー中の読み書き | すべきでない | いつでも読み取り可能 |

### 適切な用途

ref は React の外部システムとの連携に使う「避難ハッチ」。

- タイムアウト ID / インターバル ID の保存
- DOM 要素へのアクセス（フォーカス、スクロール、測定）
- JSX の計算に不要なオブジェクトの保持

### ref のアンチパターン

```tsx
// BAD: レンダー中に ref を読み書きする
function Counter() {
  const countRef = useRef(0);
  countRef.current++; // レンダー中のミューテーション
  return <p>{countRef.current}</p>; // 予測不能な表示
}

// GOOD: イベントハンドラ内で使用
function Stopwatch() {
  const intervalRef = useRef<number | null>(null);
  function handleStart() {
    intervalRef.current = setInterval(() => { /* ... */ }, 1000);
  }
  function handleStop() {
    clearInterval(intervalRef.current!);
  }
}
```

### DOM 要素への ref

```tsx
function Form() {
  const inputRef = useRef<HTMLInputElement>(null);
  function handleClick() {
    inputRef.current?.focus();
  }
  return <input ref={inputRef} />;
}
```

### 他コンポーネントの DOM へのアクセス

子コンポーネントの DOM にアクセスするには、子側で ref を受け取り組み込み要素に転送する。

```tsx
// 子: ref を props で受け取り転送
function MyInput({ ref, ...props }: ComponentProps<'input'>) {
  return <input ref={ref} {...props} />;
}

// 親: ref を渡す
function Form() {
  const inputRef = useRef<HTMLInputElement>(null);
  return <MyInput ref={inputRef} />;
}
```

`useImperativeHandle` で公開する操作を制限できる。

### React が管理する DOM を直接変更しない

React が管理する DOM ノード（テキスト内容、子要素等）を直接操作すると、React の更新と衝突する。フォーカス、スクロール等の**非破壊的な操作**に限定する。

---

## エフェクトが不要なケース

`useEffect` は外部システムとの同期のためのもの。以下のケースでは不要。

### レンダー中のデータ変換

```tsx
// BAD: state + Effect で二重レンダー
const [fullName, setFullName] = useState('');
useEffect(() => {
  setFullName(firstName + ' ' + lastName);
}, [firstName, lastName]);

// GOOD: レンダー中に計算
const fullName = firstName + ' ' + lastName;
```

### 高価な計算のキャッシュ

```tsx
// GOOD: useMemo で計算結果をキャッシュ
const visibleTodos = useMemo(
  () => getFilteredTodos(todos, filter),
  [todos, filter],
);
```

### ユーザーイベントへの応答

```tsx
// BAD: Effect で送信処理
useEffect(() => {
  if (submitted) { post('/api/data', formData); }
}, [submitted]);

// GOOD: イベントハンドラ内で直接実行
function handleSubmit() {
  post('/api/data', formData);
}
```

### props 変更時の state リセット

```tsx
// BAD: Effect で state をリセット
useEffect(() => {
  setComment('');
}, [userId]);

// GOOD: key で強制リセット
<Profile userId={userId} key={userId} />
```

### 外部ストアの購読

```tsx
// BAD: Effect + state で手動同期
useEffect(() => {
  const unsubscribe = store.subscribe(() => setData(store.getState()));
  return unsubscribe;
}, []);

// GOOD: useSyncExternalStore
const data = useSyncExternalStore(store.subscribe, store.getState);
```

---

## エフェクトのライフサイクル

### コンポーネントとは異なるライフサイクル

エフェクトはコンポーネントのマウント/アンマウントではなく、**同期の開始と停止**という視点で考える。

```tsx
useEffect(() => {
  const connection = createConnection(roomId);
  connection.connect();      // 同期の開始
  return () => {
    connection.disconnect(); // 同期の停止（クリーンアップ）
  };
}, [roomId]); // roomId が変わるたびに再同期
```

### 依存配列のルール

- エフェクトが読み取るすべての**リアクティブな値**（props, state, それらから導出した値）を含める
- 依存配列は「選ぶもの」ではなく「コードが決めるもの」
- **リンターを抑制しない** — コードを修正する

### リアクティブな値

コンポーネント本体で宣言された値は再レンダーで変わりうるため「リアクティブ」。

```tsx
function ChatRoom({ roomId }: Props) {       // roomId はリアクティブ
  const [message, setMessage] = useState(''); // message はリアクティブ
  const serverUrl = 'https://...';            // レンダーごとに同じなら非リアクティブ
  // ...
}
```

### イベントハンドラとエフェクトの違い

| | イベントハンドラ | エフェクト |
|---|---|---|
| トリガ | ユーザー操作（手動） | 依存値の変更（自動） |
| リアクティブ性 | 非リアクティブ | リアクティブ |
| 用途 | 副作用（API呼び出し等） | 外部システムとの同期 |

### useEffectEvent（実験的API）

エフェクト内で最新の値を読みたいが、その値の変更で再同期したくない場合に使う。

```tsx
const onMessage = useEffectEvent((msg: string) => {
  // 常に最新の isMuted を参照できる
  if (!isMuted) showNotification(msg);
});

useEffect(() => {
  const connection = createConnection(roomId);
  connection.on('message', onMessage);
  connection.connect();
  return () => connection.disconnect();
}, [roomId]); // isMuted は依存に含めなくてよい
```

---

## エフェクトの依存値を減らすパターン

### リンター抑制は禁止

```tsx
// BAD: リンターを抑制（古い値が永遠に使われるバグの原因）
useEffect(() => {
  // ...
  // eslint-disable-next-line react-hooks/exhaustive-deps
}, []);
```

### 依存値を減らす4つの手法

| 手法 | 場面 |
|------|------|
| **イベントハンドラへ移動** | 特定の操作に応答するコード |
| **エフェクトの分割** | 無関係な同期プロセスが混在 |
| **更新用関数** | 前の state に基づく更新（`setState(prev => ...)`) |
| **useEffectEvent** | 値を読みたいが変更に反応したくない |

### オブジェクト・関数の依存問題

レンダーごとに新しいオブジェクト/関数が作成され、不要な再同期を引き起こす。

```tsx
// BAD: レンダーごとに新しいオブジェクトが作成される
function ChatRoom({ roomId }: Props) {
  const options = { roomId, serverUrl }; // 毎回新しい参照
  useEffect(() => {
    const conn = createConnection(options);
    conn.connect();
    return () => conn.disconnect();
  }, [options]); // 毎回再同期される
}

// GOOD: エフェクト内部でオブジェクトを作成
useEffect(() => {
  const options = { roomId, serverUrl };
  const conn = createConnection(options);
  conn.connect();
  return () => conn.disconnect();
}, [roomId, serverUrl]); // プリミティブ値のみ依存
```

---

## カスタムフック

### 定義と命名

- `use` で始まり大文字が続く名前（`useOnlineStatus`, `useChatRoom`）
- 内部で他のフックを呼び出す関数
- フックを呼び出さない関数には `use` プレフィックスを付けない

```tsx
function useOnlineStatus() {
  const [isOnline, setIsOnline] = useState(true);
  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);
  return isOnline;
}
```

### State の共有ではなくロジックの共有

同じカスタムフックを複数コンポーネントで使っても、各呼び出しは**完全に独立した state** を持つ。共有されるのはロジック（振る舞い）であり、state そのものではない。

### カスタムフックにすべきケース

- 外部システムとの同期ロジック（WebSocket、ブラウザAPI等）
- 複数コンポーネントで重複するエフェクト
- 「何をしているか」を意図として明示したい場合

### アンチパターン: ライフサイクルラッパー

```tsx
// BAD: 抽象的すぎるラッパー（React のパラダイムに不適合）
function useMount(fn: () => void) {
  useEffect(fn, []); // 依存配列の検証がスキップされる
}

// GOOD: 具体的なユースケースに特化
function useChatRoom(roomId: string) {
  useEffect(() => {
    const conn = createConnection(roomId);
    conn.connect();
    return () => conn.disconnect();
  }, [roomId]);
}
```

`useMount`, `useEffectOnce`, `useUpdateEffect` のような汎用ラッパーは避ける。

---

## 再レンダリング最適化

メモ化（`React.memo`, `useMemo`, `useCallback`）に頼る前に、**設計で解決する**アプローチを優先する。

### 1. コロケーション（State リフトダウン）

state を実際に使うコンポーネントに移動し、無関係な兄弟コンポーネントの再レンダーを防ぐ。

```tsx
// BAD: 親の state 変更で ExpensiveTree も再レンダー
function App() {
  const [color, setColor] = useState('red');
  return (
    <div style={{ color }}>
      <input value={color} onChange={e => setColor(e.target.value)} />
      <ExpensiveTree /> {/* color と無関係なのに再レンダーされる */}
    </div>
  );
}

// GOOD: state を使うコンポーネントに分離
function ColorPicker() {
  const [color, setColor] = useState('red');
  return (
    <div style={{ color }}>
      <input value={color} onChange={e => setColor(e.target.value)} />
    </div>
  );
}

function App() {
  return (
    <>
      <ColorPicker />
      <ExpensiveTree /> {/* 再レンダーされない */}
    </>
  );
}
```

### 2. コンポジション（children / props パターン）

state が親要素に必須で分離できない場合、変更不要な部分を `children` や props として渡す。

```tsx
// children パターン
function ColorPicker({ children }: { children: ReactNode }) {
  const [color, setColor] = useState('red');
  return (
    <div style={{ color }}>
      <input value={color} onChange={e => setColor(e.target.value)} />
      {children} {/* 親から渡された参照は変わらない → 再レンダーされない */}
    </div>
  );
}

function App() {
  return (
    <ColorPicker>
      <ExpensiveTree />
    </ColorPicker>
  );
}
```

**メカニズム**: React は前回レンダー時から**参照同一性**を保持する要素を見つけた場合、コミットをスキップする。親から渡された `children` は state 変更時でも再生成されないため、自動的に最適化される。

### 3. React.memo（最終手段）

上記の設計パターンで解決できない場合にのみ使用する。

```tsx
const MemoExpensiveTree = memo(ExpensiveTree);

function App() {
  const [color, setColor] = useState('red');
  return (
    <div>
      <input value={color} onChange={e => setColor(e.target.value)} />
      <MemoExpensiveTree /> {/* props が変わらないため再レンダースキップ */}
    </div>
  );
}
```

### 選択基準

| パターン | 用途 | state 共有 |
|---------|------|-----------|
| **コロケーション** | state が特定部分に限定 | 不可 |
| **コンポジション** | state 共有 + 重いコンポーネントの分離 | 可能 |
| **React.memo** | 上記で解決できない場合 | 可能 |

---

## useEffect の原則

### useEffect の本質

useEffect は React ツリーの**外部システムとの同期**のためのもの。「コンポーネントが存在することの影響を表現する」ための仕組み。

### クリーンアップ関数は必須（uhyo）

クリーンアップ関数のない useEffect は原則不適格。コンポーネントのアンマウント時に影響をリセットできない実装は設計上の問題。

```tsx
// BAD: クリーンアップなし
useEffect(() => {
  window.addEventListener('resize', handleResize);
}, []);

// GOOD: クリーンアップあり
useEffect(() => {
  window.addEventListener('resize', handleResize);
  return () => window.removeEventListener('resize', handleResize);
}, []);
```

### 依存配列は最適化のためのもの

依存配列は「値の変化に反応させる」ためではなく、**不要な再実行を防ぐ最適化**として捉える。値の変化に反応させたい場合はイベントハンドラを使う。

### データフェッチは useEffect の本来の用途ではない

useEffect 内でのデータフェッチは技術的に可能だが、以下の問題がある：

1. **レース条件**: 入力のたびにリクエストが発火し、応答順序が保証されない
2. **ウォーターフォール**: ネストされたコンポーネント間で逐次的にフェッチが発生
3. **責務の肥大化**: ローディング、エラー、キャッシュを自前で管理

```tsx
// 許容: ignore フラグでレース条件を防ぐ
useEffect(() => {
  let ignore = false;
  fetchData(query).then(data => {
    if (!ignore) setData(data);
  });
  return () => { ignore = true; };
}, [query]);

// 推奨: データフェッチライブラリを使用
// TanStack Query / SWR / useSyncExternalStore
const { data } = useQuery({ queryKey: ['data', query], queryFn: () => fetchData(query) });
```

### useEffect の適切な用途の判定

| 用途 | 適切か | 理由 |
|------|--------|------|
| イベントリスナーの登録/解除 | **適切** | DOM との同期 |
| WebSocket 接続の管理 | **適切** | 外部システムとの同期 |
| データフェッチ | **許容**（ライブラリ推奨） | UI スコープに限定すれば可 |
| 派生値の計算 | **不適切** | レンダー中に直接計算する |
| 値の変化への反応 | **不適切** | イベントハンドラで処理する |
| トラッキング/分析 | **不適切** | UI と無関係 |

---

## Suspense

### 宣言的なローディング

Suspense はローディング状態を**宣言的に**記述する仕組み。コンポーネント内でデータ取得中（Promise が pending）になると、最も近い Suspense 境界の `fallback` が表示される。

```tsx
<Suspense fallback={<Skeleton />}>
  <UserProfile />
</Suspense>
```

コンポーネントは表示責務に専念でき、ローディング状態の管理コードが不要になる。

### Streaming SSR と Selective Hydration

従来の SSR はページ全体のデータ取得 → HTML 生成 → JS 読み込み → Hydration をシーケンシャルに実行する。Suspense により以下が実現する：

| 機能 | 説明 |
|------|------|
| **Streaming HTML** | 高速なコンポーネントを先行表示し、遅延コンポーネントは fallback を表示 |
| **段階的 Hydration** | ページ全体の JS 完了を待たずに、コンポーネント単位で Hydration 開始 |
| **Selective Hydration** | ユーザーがクリックした領域を優先的に Hydration |

### Suspense 境界の設計

どの粒度・範囲を Suspense で囲むかが設計上の重要な判断。

```tsx
// 粒度が粗い: ページ全体がローディング（従来と同じ）
<Suspense fallback={<PageSkeleton />}>
  <Header />
  <MainContent />
  <Sidebar />
</Suspense>

// 粒度が細かい: 各セクションが独立してロード
<Header />
<Suspense fallback={<ContentSkeleton />}>
  <MainContent />
</Suspense>
<Suspense fallback={<SidebarSkeleton />}>
  <Sidebar />
</Suspense>
```

**原則**: 「アプリの最も遅い部分が、高速な部分を引きずらない」ように境界を設計する。

### Suspense 対応のデータフェッチ

Suspense を活用するには、対応したライブラリ・フレームワーク（TanStack Query, SWR, Next.js 等）を使用する。自前で Promise を throw する実装は公式に推奨されていない。

---

## コンポーネント設計の実践

### 関数を小さく保つ

1コンポーネントあたりのフック数は **約5個まで**を目安にする。超える場合はロジックの抽出や分割を検討する。

```tsx
// BAD: 巨大なコンポーネント（ダイアログ、メニュー、コンテンツ処理が混在）
function Dashboard() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [data, setData] = useState(null);
  const [filter, setFilter] = useState('');
  const [sort, setSort] = useState('date');
  const [page, setPage] = useState(1);
  // ... 巨大な JSX
}

// GOOD: 責務ごとに分割
function Dashboard() {
  return (
    <DashboardLayout>
      <DashboardMenu />
      <DashboardContent />
      <DashboardDialog />
    </DashboardLayout>
  );
}
```

state 変更がコンポーネント内に閉じるため、パフォーマンスも向上する。

### ビジネスロジックの抽出

React/DOM に依存しない純粋な TypeScript 関数としてビジネスロジックを抽出する。テスタビリティが大幅に向上する。

```tsx
// ビジネスロジック: 純粋関数（React 非依存）
function calculateDiscount(price: number, memberRank: MemberRank): number {
  // テストが容易
}

// フック: React の世界との橋渡し
function useCheckout(items: Item[]) {
  const { data: member } = useQuery({ queryKey: ['member'], queryFn: fetchMember });
  const total = items.reduce((sum, item) => sum + item.price, 0);
  const discount = member ? calculateDiscount(total, member.rank) : 0;
  return { total, discount, finalPrice: total - discount };
}
```

### スコープの最小化

state や Context のスコープは可能な限り狭くする。

- **props のバケツリレー**は Context の乱用より好ましい（データフローが明示的）
- Context は**消費場所が予測不能**な場合にのみ使用する（テーマ、Snackbar 等）
- グローバルストアへの安易な依存は複雑性を爆発させる

### 過度な共通化の回避

> コードの重複による痛みは、共通コンポーネントの痛みより小さいことが多い

共通コンポーネントに条件分岐 props が積み重なるより、適度な重複を許容して責務を分離する方が保守性が高い。

---

## インポート・エクスポート

### default export vs named export

| | default export | named export |
|---|---|---|
| ファイルあたりの数 | 1つ | 無制限 |
| import 構文 | `import X from '...'`（名前自由） | `import { X } from '...'`（名前一致必須） |

- チーム内でどちらかに統一する
- 無名デフォルトエクスポート `export default () => {}` は避ける（デバッグ困難）

---

## React Hook Form

### コンポーネント設計: Base + Control の2層分離

React Hook Form（RHF）に依存しない Base コンポーネントと、RHF と接続する Control コンポーネントに分離する。

```tsx
// Base: RHF 非依存。useState での単独利用も可能
type InputProps = {
  value: string;
  onChange: (value: string) => void;
  onBlur?: () => void;
  inputRef?: Ref<HTMLInputElement>;
};

function Input({ value, onChange, onBlur, inputRef }: InputProps) {
  return <input ref={inputRef} value={value} onChange={e => onChange(e.target.value)} onBlur={onBlur} />;
}

// Control: RHF の useController で接続
function InputControl<T extends FieldValues>({ name, control }: { name: Path<T>; control: Control<T> }) {
  const { field } = useController({ name, control });
  return <Input {...field} />;
}
```

Base コンポーネントは検索バー等の単純な `useState` 利用でも再利用でき、テストも容易になる。

### defaultValues の注意点

RHF は `defaultValues` を初回レンダー時にキャッシュする。非同期データを `defaultValues` に渡す場合、データ確定前にフォームをレンダーしない。

```tsx
// BAD: profile が undefined → {} でキャッシュされ、データ取得後も更新されない
const { data: profile } = useProfile();
return <Form defaultValues={profile} />;

// GOOD: データ確定後にフォームをマウント
const { isLoading, data: profile } = useProfile();
if (isLoading) return <Loading />;
return <Form defaultValues={profile} />;
```

型安全のため、`defaultValues` を必須にするラッパーを作ると初期化漏れを防げる。

```tsx
const useStrictForm = <T extends FieldValues>(
  props: UseFormProps<T> & { defaultValues: T },
): UseFormReturn<T> => useForm(props);
```

### watch() の再レンダー問題

`watch()` をコンポーネントのトップレベルで呼ぶと、監視対象の変更で**コンポーネント全体**が再レンダーされる。`useWatch` + 子コンポーネント分離で影響範囲を局所化する。

```tsx
// BAD: フォーム全体が再レンダー
function MyForm() {
  const { watch, control } = useForm();
  const password = watch('password'); // ← 全体が再レンダー
  return (
    <form>
      <input {...register('email')} />
      <input {...register('password')} />
      <PasswordStrength password={password} />
    </form>
  );
}

// GOOD: useWatch を子コンポーネントに隔離
function PasswordStrengthWatch({ control }: { control: Control }) {
  const password = useWatch({ name: 'password', control });
  const score = zxcvbn(password).score;
  return <PasswordStrength score={score} />;
}

function MyForm() {
  const { register, control } = useForm();
  return (
    <form>
      <input {...register('email')} />
      <input {...register('password')} />
      <PasswordStrengthWatch control={control} /> {/* ここだけ再レンダー */}
    </form>
  );
}
```

計算結果が段階的に変化する場合（スコア 0-4 等）、`useMemo` で子の再レンダーをさらに絞れる。

### setError のキー設計

クロスフィールドバリデーション（パスワード一致等）で `setError` を使う場合、既存フィールドのネストパスを避ける。RHF はフィールド配下のエラーを submit 前にクリアするため、ネストキーはバイパスされる。

```tsx
// BAD: confirmPassword.* として扱われ、submit 前にクリアされる
setError('confirmPassword.isSamePassword', { message: '一致しません' });

// GOOD: フラットなキー名
setError('confirmPasswordMismatch', { message: '一致しません' });
```

### valueAsNumber の罠

`valueAsNumber` は `null` を `0` に変換する（HTML の `valueAsNumber` 仕様に準拠）。`null` を保持したい場合は `setValueAs` を使う。

```tsx
// BAD: null が 0 になる
<input {...register('maxMinutes', { valueAsNumber: true })} />

// GOOD: null を保持
<input {...register('maxMinutes', {
  setValueAs: v => v == null || v === '' ? null : Number(v),
})} />
```

`setValueAs` / `valueAs*` はテキスト系入力のみ有効。radio / checkbox には適用されない。

---

## 参考資料

- [初めてのコンポーネント](https://ja.react.dev/learn/your-first-component)
- [コンポーネントのインポートとエクスポート](https://ja.react.dev/learn/importing-and-exporting-components)
- [JSX でマークアップを記述する](https://ja.react.dev/learn/writing-markup-with-jsx)
- [コンポーネントに props を渡す](https://ja.react.dev/learn/passing-props-to-a-component)
- [条件付きレンダー](https://ja.react.dev/learn/conditional-rendering)
- [リストのレンダー](https://ja.react.dev/learn/rendering-lists)
- [コンポーネントを純粋に保つ](https://ja.react.dev/learn/keeping-components-pure)
- [UI をツリーとして理解する](https://ja.react.dev/learn/understanding-your-ui-as-a-tree)
- [イベントへの応答](https://ja.react.dev/learn/responding-to-events)
- [state: コンポーネントのメモリ](https://ja.react.dev/learn/state-a-components-memory)
- [レンダーとコミット](https://ja.react.dev/learn/render-and-commit)
- [state はスナップショットである](https://ja.react.dev/learn/state-as-a-snapshot)
- [一連の state の更新をキューに入れる](https://ja.react.dev/learn/queueing-a-series-of-state-updates)
- [state 内のオブジェクトの更新](https://ja.react.dev/learn/updating-objects-in-state)
- [state 内の配列の更新](https://ja.react.dev/learn/updating-arrays-in-state)
- [state を使って入力に反応する](https://ja.react.dev/learn/reacting-to-input-with-state)
- [state 構造の選択](https://ja.react.dev/learn/choosing-the-state-structure)
- [state の保持とリセット](https://ja.react.dev/learn/preserving-and-resetting-state)
- [state ロジックをリデューサに抽出する](https://ja.react.dev/learn/extracting-state-logic-into-a-reducer)
- [コンテクストで深くデータを渡す](https://ja.react.dev/learn/passing-data-deeply-with-context)
- [リデューサとコンテクストでスケールアップ](https://ja.react.dev/learn/scaling-up-with-reducer-and-context)
- [ref で値を参照する](https://ja.react.dev/learn/referencing-values-with-refs)
- [ref で DOM を操作する](https://ja.react.dev/learn/manipulating-the-dom-with-refs)
- [エフェクトは不要かもしれない](https://ja.react.dev/learn/you-might-not-need-an-effect)
- [リアクティブなエフェクトのライフサイクル](https://ja.react.dev/learn/lifecycle-of-reactive-effects)
- [イベントとエフェクトを切り離す](https://ja.react.dev/learn/separating-events-from-effects)
- [エフェクトから依存値を取り除く](https://ja.react.dev/learn/removing-effect-dependencies)
- [カスタムフックでロジックを再利用する](https://ja.react.dev/learn/reusing-logic-with-custom-hooks)
- [コンポーネントとフックは純粋でなければならない](https://ja.react.dev/reference/rules/components-and-hooks-must-be-pure)
- [React はコンポーネントとフックを呼び出す](https://ja.react.dev/reference/rules/react-calls-components-and-hooks)
- [フックのルール](https://ja.react.dev/reference/rules/rules-of-hooks)
- [Compound Components と TypeScript による型安全な設計](https://levtech.jp/media/article/column/detail_736/)
- [Container/Presentational パターン再入門](https://zenn.dev/buyselltech/articles/9460c75b7cd8d1)
- [React Suspense についてまとめる](https://zenn.dev/tm35/articles/0a64177c0a41bd)
- [制御/非制御コンポーネントと Atoms 設計](https://zenn.dev/takepepe/articles/universal-framework-atoms)
- [React パフォーマンス最適化: コンポジションパターン](https://zenn.dev/counterworks/articles/react-composition)
- [React の key テクニックをインスタンスの観点で理解する](https://zenn.dev/uhyo/articles/react-key-techniques)
- [useEffect から Suspense への移行](https://zenn.dev/takagimeow/articles/switch-from-useeffect-to-suspense)
- [データフェッチは useEffect の出番じゃない](https://zenn.dev/kazuma1989/articles/a30ba6e29b5b4c)
- [React の再レンダリング最適化パターン](https://zenn.dev/azukiazusa/articles/react-rerender-patterns)
- [React における純粋なコンポーネント](https://zenn.dev/uhyo/articles/react-pure-components)
- [use RFC と Promise をデータとして扱うパラダイム](https://zenn.dev/uhyo/articles/react-use-rfc-2)
- [useEffect の正しい使い方（過激派）](https://zenn.dev/uhyo/articles/useeffect-taught-by-extremist)
- [useEffect の不適切な使い方まとめ](https://zenn.dev/fujiyama/articles/c26acc641c4e30)
- [ComponentProps 型を使った Atoms 設計](https://zenn.dev/takepepe/articles/atoms-type-definitions)
- [良い React コードの書き方](https://kaminashi-developer.hatenablog.jp/entry/2025/3/17/intro-react)
- [State Reducer パターンによるコンポーネント拡張](https://zenn.dev/grooves/articles/a1d268ac45ed67)
- [React Hook Form の落とし穴と注意点](https://zenn.dev/yodaka/articles/e490a79bccd5e2)
- [React Hook Form useWatch による再レンダー最適化](https://zenn.dev/takepepe/articles/rhf-usewatach)
- [React Hook Form のベストプラクティス: 型安全と設計分離](https://zenn.dev/yuitosato/articles/292f13816993ef)
