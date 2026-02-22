## コンポーネント設計パターン

詳細は /web-frontend スキルを参照（コンポーネント分類、Props 設計）も参照。

### Container / Presentational

| | Container | Presentational |
|---|---|---|
| 責務 | ロジック（データ取得、state） | UI 表現 |
| データ源 | API・hooks | props のみ |

hooks → Container → Presentational の3層を疎結合に保つ。Presentational はグローバル状態や外部 API に直接依存しない。

### Compound Components

親子コンポーネント群が Context で暗黙的にデータを共有し、使用者がレイアウトを自由に構成できるパターン。

```tsx
<Tabs defaultValue="a">
  <Tab value="a">タブA</Tab>
  <Tab value="b">タブB</Tab>
  <TabPanel value="a">コンテンツA</TabPanel>
  <TabPanel value="b">コンテンツB</TabPanel>
</Tabs>
```

親が状態を一元管理し Context で供給、子が `useContext` で取得。新要素の追加が既存コードに影響しない。

### Render Hooks

関連する state と UI をカスタムフックにカプセル化する。

```tsx
function useModal() {
  const [isOpen, setIsOpen] = useState(false);
  const renderModal = (children: ReactNode) => (
    <Modal isOpen={isOpen} onClose={() => setIsOpen(false)}>{children}</Modal>
  );
  return { onOpen: () => setIsOpen(true), renderModal };
}
```

### 制御/非制御コンポーネント

| | 制御 | 非制御 |
|---|---|---|
| 状態管理 | React（useState） | DOM 自身 |
| RHF | `useController` | `register()` |

### ComponentProps パターン

```tsx
type TextFieldProps = React.ComponentProps<'input'> & { label: string; error?: string };

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

`Omit<ComponentProps<'input'>, 'className'>` で特定 props を型レベルで禁止可能。

---

## Async React（Suspense / Transition）

非同期処理を前提に最適な UX を目指す設計思想（React 19〜）。Suspense と Transition が基盤。

> Async React の理想は、トランジションの「意味」をプログラマーが考えて、具体的な挙動は React がよしなにやってくれること。これは宣言的 UI の拡張である。 — uhyo

### Suspense

宣言的なローディング。コンポーネントが pending になると最も近い Suspense 境界の `fallback` が表示される。

```tsx
<Suspense fallback={<Skeleton />}>
  <UserProfile />
</Suspense>
```

- **Suspense は前提** — オプションではなく非同期 React の基盤
- **境界の設計**: 最も遅い部分が高速な部分を引きずらないよう分割する
- Suspense 対応のデータフェッチには TanStack Query / SWR / Next.js 等を使用。自前で Promise を throw しない

### Transition

`startTransition` で非同期更新をマークすると、更新中も前の UI を維持しインタラクティブに保つ。Suspense フォールバックへの即時切り替えを防ぎ、ちらつきを抑制する。

```tsx
// BAD: 手動ローディング管理
const [isPending, setIsPending] = useState(false);
const handleClick = async () => {
  setIsPending(true); await submitData(); setIsPending(false);
};

// GOOD: React がスケジューリング管理
const [isPending, startTransition] = useTransition();
const handleClick = () => {
  startTransition(async () => { await submitData(); router.navigate('/next'); });
};
```

### Action パターン（汎用コンポーネント設計）

汎用コンポーネントが `action` prop を受け取り、内部で `startTransition` を適用。アプリ全体で一貫した非同期 UX を実現する。

```tsx
function Button({ action, children }: ButtonProps) {
  const [isPending, startTransition] = useTransition();
  return (
    <button disabled={isPending} onClick={(e) => startTransition(() => action(e))}>
      {isPending ? <Spinner /> : children}
    </button>
  );
}

// 使用側: 同期的なコードで非同期処理を記述
<Button action={async () => {
  await login(fields);
  await prefetchDashboard();
  router.navigate('/');
}}>ログイン</Button>
```

### useOptimistic

Transition 中に楽観的な値を即座に表示し、完了後に実際の値へ置換する。

```tsx
const [optimisticLikes, addOptimisticLike] = useOptimistic(
  likes, (cur, newLike: Like) => [...cur, newLike]
);
// addOptimisticLike(tempLike) → 即 UI 反映、await api.addLike() → サーバー送信
```

### ネットワーク速度と UX の自動分岐

Transition + Suspense により、ネットワーク速度に応じた UX が自動的に実現される。

| 速度 | UX |
|------|-----|
| 高速（<150ms） | 即座に遷移、ローディング表示なし |
| 中速（150ms〜1s） | Transition が前画面を維持、完了後に切替 |
| 低速（>1s） | Suspense フォールバック表示 |

参考: [uhyo - React 19時代のコンポーネント設計ベストプラクティス](https://speakerdeck.com/uhyo/react-19shi-dai-nokonponentoshe-ji-besutopurakuteisu) / [rickhanlonii/async-react](https://github.com/rickhanlonii/async-react)

---

## 設計の実践

- **~5 hooks/コンポーネント** を目安にし、超える場合は分割を検討
- **ビジネスロジックは React 非依存の純粋関数として抽出** — テスタビリティ向上
- **state/Context のスコープは最小に** — props バケツリレーは Context 乱用より好ましい
- **過度な共通化を避ける** — 条件分岐 props の蓄積より適度な重複が保守的

---

## React Hook Form

### Base + Control の2層分離

RHF 非依存の Base と、RHF 接続の Control に分離。Base は `useState` でも再利用可能。

```tsx
// Base: RHF 非依存
function Input({ value, onChange, onBlur, inputRef }: InputProps) {
  return <input ref={inputRef} value={value} onChange={e => onChange(e.target.value)} onBlur={onBlur} />;
}

// Control: useController で接続
function InputControl<T extends FieldValues>({ name, control }: { name: Path<T>; control: Control<T> }) {
  const { field } = useController({ name, control });
  return <Input {...field} />;
}
```

### defaultValues の注意点

RHF は初回レンダー時に `defaultValues` をキャッシュする。非同期データはデータ確定後にマウント。

```tsx
// BAD: undefined → {} でキャッシュ
return <Form defaultValues={profile} />;

// GOOD
if (isLoading) return <Loading />;
return <Form defaultValues={profile} />;
```

型安全: `defaultValues: T` を必須にするラッパーで初期化漏れ防止。

### watch() の再レンダー問題

`watch()` は監視対象の変更で**コンポーネント全体**が再レンダー。`useWatch` + 子コンポーネント分離で局所化。

```tsx
// GOOD: useWatch を子に隔離
function PasswordStrengthWatch({ control }: { control: Control }) {
  const password = useWatch({ name: 'password', control });
  return <PasswordStrength score={zxcvbn(password).score} />;
}
```

### setError のキー設計

クロスフィールドバリデーションでは**フラットなキー名**を使う。ネストパスは submit 前にクリアされる。

```tsx
// BAD: submit 前にクリアされる
setError('confirmPassword.isSamePassword', { message: '...' });

// GOOD
setError('confirmPasswordMismatch', { message: '...' });
```

### valueAsNumber の罠

`null` を `0` に変換する（HTML 仕様）。`null` を保持するには `setValueAs` を使う。

```tsx
// BAD: null → 0
register('maxMinutes', { valueAsNumber: true })

// GOOD: null 保持
register('maxMinutes', { setValueAs: v => v == null || v === '' ? null : Number(v) })
```

`setValueAs` / `valueAs*` はテキスト系入力のみ有効。radio / checkbox には適用されない。
