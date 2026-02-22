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

メディアクエリに頼らず、コンテンツとコンテナのサイズに自動適応するレイアウトを構築する。
『Every Layout』のレイアウトプリミティブを参考に、Tailwind で実装する。

### 設計思想

**レイアウト（配置）と装飾（見た目）を分離する。** 巨大な div に全部詰め込まない。

```tsx
// BAD: 1つの div にレイアウト・装飾・余白を混在
<div className="flex flex-col md:flex-row gap-4 p-6 bg-white rounded-lg shadow-md border">
  {/* すべてが1つのdivに依存 */}
</div>

// GOOD: レイアウト層と装飾層を分離
<div className="flex flex-col gap-6">       {/* レイアウト: 余白管理 */}
  <div className="rounded-lg border p-6">   {/* 装飾: 見た目 */}
    <div className="flex flex-wrap gap-4">   {/* レイアウト: 水平配置 */}
      <span className="rounded-full bg-blue-100 px-3 py-1">React</span>
      <span className="rounded-full bg-blue-100 px-3 py-1">TypeScript</span>
    </div>
  </div>
</div>
```

### Flex vs Grid の選択基準

```
どちらを使う？
    ↓
ページレベルの分割？（サイドバー + メイン等）
    ├─ Yes → Grid（minmax(0, 1fr) でネスト問題を構造的に回避）
    └─ No → コンポーネント内のレイアウト
              ├─ 1次元の並び？（ナビ、ボタン群、タグ等）
              │     └─ Yes → Flex（方向と gap で十分、必要なら min-w-0）
              └─ 2次元グリッド？（カード一覧等）
                    └─ Yes → Grid（auto-fit + minmax）
```

**Flex が得意**: 1次元の並び、折り返し（`flex-wrap`）、均等配置
**Grid が得意**: 固定＋可変カラム、2次元配置、構造的なレイアウト制御

### Flexbox の `min-width: auto` 罠

Flexbox の子要素にはデフォルトで `min-width: auto` が適用され、**コンテンツ幅以下に縮まない**。
長いテキストやコードブロックがあると、親をはみ出してレイアウトが崩れる。

```tsx
// BAD: 長いコンテンツが親をはみ出す
<div className="flex gap-2">
  <span className="shrink-0">ラベル</span>
  <p>とても長いテキスト...</p>
</div>

// GOOD: Flex → min-w-0 で縮小を許可（コンポーネント内の小さなレイアウトに適切）
<div className="flex gap-2">
  <span className="shrink-0">ラベル</span>
  <p className="min-w-0 flex-1">長いテキストも正しく折り返される...</p>
</div>

// GOOD: Grid → minmax(0, 1fr) で構造的に制約（固定+可変カラムに適切）
<div className="grid grid-cols-[auto_minmax(0,1fr)] gap-2">
  <span>ラベル</span>
  <p>長いテキストも正しく折り返される...</p>
</div>
```

**注意: `min-w-0` はネストで伝播しない。** Flex 内にさらに Flex を入れると、内側でも `min-w-0` が必要になる。ページレベルの分割（サイドバー等）では Grid を使い、コンポーネント内の小さなレイアウトでは Flex + `min-w-0` で十分。

### 余白管理の原則

> 要素自身にマージンを持たせず、**親が子の間隔を管理する**。

```tsx
// BAD: 各要素が自分のマージンを持つ
<h2 className="mb-4">見出し</h2>
<p className="mb-4">本文</p>

// GOOD: 親が gap で間隔を管理
<div className="flex flex-col gap-4">
  <h2>見出し</h2>
  <p>本文</p>
</div>
```

**`gap` vs `space-y`**: `gap` を優先する。`space-y` は margin ベースのため、`hidden` 要素があると余白が崩れる。`gap` は Flexbox/Grid のネイティブ機能で、表示要素間のみに適用される。

### レイアウトパターン集

#### ページ分割: Grid による2/3カラム

`minmax(0, 1fr)` でメイン領域の子孫すべてが自動で幅制約される。

```tsx
{/* 2カラム */}
<div className="grid grid-cols-[250px_minmax(0,1fr)] min-h-screen">
  <aside>サイドバー</aside>
  <main>メイン</main>
</div>

{/* 3カラム */}
<div className="grid grid-cols-[250px_minmax(0,1fr)_300px] min-h-screen">
  <nav>ナビ</nav>
  <main>メイン</main>
  <aside>サブ</aside>
</div>

{/* レスポンシブ: モバイル1カラム → デスクトップ2カラム */}
<div className="grid grid-cols-1 md:grid-cols-[250px_minmax(0,1fr)] min-h-screen">
  <aside>サイドバー</aside>
  <main>メイン</main>
</div>
```

#### 水平並び: Flex による1次元レイアウト

ナビゲーション、ボタン群、タグクラウドなど。

```tsx
{/* 折り返しあり（タグクラウド等） */}
<div className="flex flex-wrap gap-2">
  <span className="rounded-full bg-blue-100 px-3 py-1 text-sm">React</span>
  <span className="rounded-full bg-blue-100 px-3 py-1 text-sm">TypeScript</span>
</div>

{/* コンポーネント内の分割（狭くなったら自動折り返し） */}
<div className="flex flex-wrap gap-4">
  <aside className="w-64 shrink-0 grow-0">サブ</aside>
  <main className="min-w-[50%] grow">メイン</main>
</div>
```

#### カード一覧: Grid の auto-fit

**メディアクエリなし**でカラム数を自動調整。コンテナクエリとの組み合わせも可。

```tsx
{/* 各カードが最低250px、余白があれば自動で列を増やす */}
<div className="grid grid-cols-[repeat(auto-fit,minmax(250px,1fr))] gap-6">
  {items.map(item => <Card key={item.id} {...item} />)}
</div>

{/* コンテナクエリで閾値ベースの切り替えも可 */}
<div className="@container">
  <div className="flex flex-col @md:flex-row gap-4">
    <div className="flex-1">カード1</div>
    <div className="flex-1">カード2</div>
  </div>
</div>
```

#### 中央揃え: Cover パターン

ファーストビューや全画面セクション。

```tsx
<div className="flex min-h-screen flex-col">
  <header>ヘッダー</header>
  <main className="flex flex-1 items-center justify-center">
    <h1>中央コンテンツ</h1>
  </main>
  <footer>フッター</footer>
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
