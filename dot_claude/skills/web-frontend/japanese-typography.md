## 日本語タイポグラフィ

日本語UIで AI 生成コードが崩れやすいポイントと、Tailwind での対処パターン。
英語圏のデフォルト値をそのまま使うと日本語では読みにくくなる箇所を重点的にカバーする。

---

### コンテキスト別タイポグラフィ

本文・テーブル・フォーム・ダッシュボードで同じ `line-height` / `letter-spacing` を使わない。
日本語は文字の高さが英語より大きく、漢字・ひらがな・カタカナの混在で視覚密度が高い。

| コンテキスト | line-height | letter-spacing | font-size 目安 | 備考 |
|-------------|-------------|----------------|---------------|------|
| **本文** | `1.8`〜`2.0` | `0.04em`〜`0.06em` | `base`（16px） | 長文の可読性を最優先 |
| **見出し** | `1.3`〜`1.5` | `0.02em`〜`0.04em` | `xl`〜`3xl` | 行間を詰めて塊感を出す |
| **テーブル** | `1.4`〜`1.5` | `0`〜`0.02em` | `sm`（14px） | 密度重視、行間は本文より狭く |
| **フォーム** | `1.5`〜`1.6` | `0.02em` | ラベル `sm` / 入力 `base` | ラベルと入力でサイズ・ウェイトを分ける |
| **ダッシュボード数値** | `1.2`〜`1.4` | `0` | `lg`〜`2xl` | 等幅フォント（`font-mono`）推奨 |

```tsx
// BAD: 全体に同じ line-height
<div className="leading-normal">  {/* 1.5 — 英語向け */}
  <p>本文テキスト...</p>
  <table>...</table>
</div>

// GOOD: コンテキストごとに切り替え
<article className="leading-[1.8] tracking-[0.04em]">
  <h2 className="leading-tight tracking-[0.02em]">見出し</h2>
  <p>本文テキスト...</p>
</article>
<table className="leading-snug text-sm tracking-normal">...</table>
```

---

### 和欧混植（日本語と英語の混在）

日本語の中に英数字が入ると、文字間の詰まり具合が不均一になり「浮く」。

#### CSS での対処

```css
/* globals.css */
body {
  /* ブラウザに和欧間スペースの自動調整を任せる */
  text-autospace: ideograph-alpha ideograph-numeric;
}
```

`text-autospace` は CSS Text Level 4 のプロパティで、Chrome 120+ / Edge 120+ で対応済み。
未対応ブラウザでは無視されるだけなので、progressive enhancement として安全に使える。

#### フォントスタック

```css
/* globals.css */
:root {
  --font-sans: "Inter", "Noto Sans JP", "Hiragino Sans", "Hiragino Kaku Gothic ProN", sans-serif;
}
```

- 英字フォントを先に指定し、日本語フォントでフォールバック
- `Noto Sans JP` は Google Fonts から Variable Font で読み込むと軽量
- `Hiragino Sans` は macOS / iOS のシステムフォント（追加読み込み不要）

---

### 見出しの折り返し制御

日本語の見出しは、助詞（は・が・を・に・の）の直前で折り返されると読みにくい。

```tsx
// 折り返し位置を制御
<h2 className="text-balance">
  プロダクト開発における品質と速度のトレードオフ
</h2>
```

| プロパティ | 効果 | 用途 |
|-----------|------|------|
| `text-balance` | 各行の長さを均等に分配 | 見出し（4行以下） |
| `text-pretty` | 孤立語（widow）を防止 | 本文の最終行 |

`text-wrap: balance` は Chrome 114+ / Firefox 121+ で対応。見出しに限定して使う（本文全体に適用するとパフォーマンスに影響）。

---

### 禁則処理

ブラウザのデフォルト禁則処理に加え、`word-break` で制御する。

```tsx
// 日本語本文: 厳格な禁則処理
<p className="break-normal">
  句読点が行頭に来ない、括弧の分離を防ぐ
</p>

// 長い英単語・URL が混在する場合: オーバーフロー防止
<p className="break-words">
  https://example.com/very-long-path を含む文章
</p>
```

| Tailwind | CSS | 効果 |
|----------|-----|------|
| `break-normal` | `word-break: normal` | 禁則処理あり、英単語は途中で切らない |
| `break-words` | `overflow-wrap: break-word` | はみ出す単語のみ途中で折り返す |
| `break-all` | `word-break: break-all` | すべての文字間で折り返し可（テーブルセル等の極端に狭い場面のみ） |

---

### Tailwind 設定例

プロジェクトの `tailwind.config.ts` で日本語向けのデフォルトを定義する。

```typescript
// tailwind.config.ts
export default {
  theme: {
    extend: {
      fontSize: {
        // line-height を日本語向けに上書き
        base: ['1rem',     { lineHeight: '1.8' }],
        lg:   ['1.125rem', { lineHeight: '1.75' }],
        sm:   ['0.875rem', { lineHeight: '1.5' }],
      },
      letterSpacing: {
        'ja': '0.04em',       // 日本語本文
        'ja-tight': '0.02em', // 見出し
      },
    },
  },
};
```

これにより `text-base` を使うだけで日本語に適した `line-height: 1.8` が適用される。
