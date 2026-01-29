---
name: ui-design-principles
description: ビジュアルデザインの原則に基づいてUIをレビュー。スペーシング、タイポグラフィ、視覚的階層、コントラストなどをチェック。
argument-hint: "[file-or-pattern]"
---

# UI Design Principles Skill

論理的なビジュアルデザインの原則に基づいてUIをレビューする。

## When to Use This Skill

Trigger when user:
- `/ui-design-principles` コマンドを実行
- 「デザインをレビューして」「見た目を改善して」と依頼
- スペーシングやタイポグラフィの問題を確認したい場合

## 核心原則

**「AIっぽいダサいデザイン」を避ける**

- 文脈に応じた思考
- 予想外だが適切な選択
- 大胆なデザイン決定

---

## チェック項目

### 1. タイポグラフィ（Anthropic公式推奨）

#### 避けるべきフォント
```
❌ Inter, Roboto, Open Sans, Lato, Arial, system-ui
```

#### 推奨フォント

| カテゴリ | フォント |
|---------|---------|
| コード風 | JetBrains Mono, Fira Code, Space Grotesk |
| エディトリアル | Playfair Display, Crimson Pro |
| テクニカル | IBM Plex family, Source Sans 3 |
| 個性的 | Bricolage Grotesque, Newsreader |

#### タイポグラフィのルール

- **コントラストの高い組み合わせ**: Display + Monospace、Serif + Geometric Sans
- **極端なウェイト差**: 100/200 vs 800/900
- **サイズジャンプ**: 1.5xではなく**3x以上**
- **1つの個性的なフォント**を選び、決定的に適用

```css
/* 見出しの文字間隔を狭く */
h1, h2, h3 {
  letter-spacing: -0.02em;
  font-weight: 800;
}

/* サイズジャンプ 3x以上 */
h1 { font-size: 3rem; }    /* 48px */
body { font-size: 1rem; }  /* 16px */
```

### 2. カラー＆テーマ

- **CSS変数**で一貫性を確保
- **支配的な色 + シャープなアクセント** > 控えめな分散パレット
- IDEテーマや文化的美学からインスピレーション
- ジェネリックなデフォルトを避ける

```css
:root {
  --color-primary: #0066ff;
  --color-accent: #ff3366;  /* シャープなアクセント */
  --color-bg: #0a0a0a;
}
```

### 3. モーション

- HTMLは**CSS-only**ソリューションを優先
- Reactは**Motion/Framer Motion**ライブラリを使用
- **高インパクトな瞬間**に集中
- ページロード時のスタガードリビール（段階的表示）

```css
/* スタガードリビール */
.item {
  animation: fadeIn 0.5s ease-out forwards;
  animation-delay: calc(var(--index) * 0.1s);
}
```

### 4. 背景

- ソリッドカラーのデフォルトを避ける
- **レイヤードCSSグラデーション**
- **幾何学パターン**
- 全体の美学に合った**コンテキスト効果**

```css
background:
  radial-gradient(circle at 20% 50%, rgba(0, 102, 255, 0.1) 0%, transparent 50%),
  radial-gradient(circle at 80% 50%, rgba(255, 51, 102, 0.1) 0%, transparent 50%),
  #0a0a0a;
```

### 5. スペーシング（8ptグリッドシステム）

- 関連性の高い要素は近くに配置
- 関連性の低い要素はスペースで分離
- **8の倍数**でスペーシング（8, 16, 24, 32, 40, 48...）

```
❌ padding: 13px 17px;
✅ padding: 16px 24px;
```

### 6. コントラスト比

| 対象 | 最小コントラスト比 |
|------|-------------------|
| UI要素（アイコン、ボーダー等） | 3:1 |
| 大きいテキスト（18px以上） | 3:1 |
| 小さいテキスト | 4.5:1 |

### 7. タッチターゲット

- 最小サイズ: **48×48px**
- 隣接するターゲット間に十分なスペース

### 8. ボタンの階層

- **プライマリボタン**: 1画面に1つのみ強調
- **セカンダリボタン**: 控えめなスタイル

### 9. 視覚的階層とアライメント

- アライメントの混在を避ける
- 一貫したアライメントで認知負荷を軽減
- 重要な要素はサイズ・色・位置で強調

### 10. シンプルさ vs ミニマリズム

- **シンプル**: 不要な複雑さを排除
- 重要な情報の削除はユーザビリティを損なう
- ラベル、説明文、ヘルプテキストは必要に応じて残す

---

## 出力形式

```
src/components/Button.tsx:15 - ボタンサイズが48px未満（現在: 32px）
src/styles/globals.css:42 - 8ptグリッドに準拠していないスペーシング（13px）
src/styles/globals.css:10 - ジェネリックフォント使用（Inter → JetBrains Monoなどを検討）
src/pages/index.tsx:78 - 複数のプライマリボタンが存在
src/components/Hero.tsx:5 - ソリッドカラー背景（グラデーションを検討）
```

## 使用例

```
/ui-design-principles src/components/**/*.tsx
/ui-design-principles src/styles/
```
