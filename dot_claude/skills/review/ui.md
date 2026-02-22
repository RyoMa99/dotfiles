# UI Check

UIコンポーネントの技術的実装とビジュアルデザインを包括的にチェックする。

## 実行フロー

### Step 1: 対象ファイルの特定

引数があればそのファイル、なければ直前に作成・編集したUIファイルを対象にする。

### Step 2: Web Interface Guidelines チェック

最新のガイドラインをフェッチして適用:

```
https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
```

**チェック項目**:
- アクセシビリティ（aria属性、キーボード操作、スクリーンリーダー）
- フォーム（autocomplete、ラベル、エラー表示）
- パフォーマンス（画像サイズ、リスト仮想化）
- アニメーション（prefers-reduced-motion対応）
- ナビゲーション（URL状態同期、確認ダイアログ）
- リンクセキュリティ（`target="_blank"` に `rel="noopener noreferrer"`）

### Step 3: アクセシビリティ詳細チェック

#### disabled ボタンのアンチパターン

disabled ボタンはスクリーンリーダーに読み上げられず、なぜ操作できないのか理由が伝わらない。

```typescript
// BAD: disabled で操作不能にするだけ
<button disabled={!isValid}>送信</button>

// GOOD: aria-disabled + 理由の説明
<button
  aria-disabled={!isValid}
  onClick={!isValid ? undefined : handleSubmit}
  aria-describedby={!isValid ? "submit-hint" : undefined}
>
  送信
</button>
{!isValid && (
  <p id="submit-hint" className="text-sm text-muted">
    すべての必須項目を入力してください
  </p>
)}
```

**判断基準**:
- `disabled`: ユーザーに操作不可の理由を伝える必要がない場合（例: ローディング中の一時的な無効化）
- `aria-disabled` + 説明: フォームの未入力など、ユーザーが対処できる場合

#### フォーム a11y パターン

```typescript
// 必須のフォームフィールド
<div>
  <label htmlFor="email">
    メールアドレス
    <span aria-hidden="true"> *</span>
  </label>
  <input
    id="email"
    type="email"
    required
    aria-required="true"
    aria-invalid={!!errors.email}
    aria-describedby={errors.email ? "email-error" : undefined}
  />
  {errors.email && (
    <p id="email-error" role="alert">
      {errors.email.message}
    </p>
  )}
</div>
```

**チェック項目**:
- `<label>` と `<input>` が `htmlFor` / `id` で紐づいているか
- エラーメッセージが `aria-describedby` で関連付けられているか
- エラー表示時に `role="alert"` でスクリーンリーダーに通知されるか
- 必須フィールドに `aria-required="true"` が設定されているか
- 入力エラー時に `aria-invalid="true"` が設定されているか

#### axe-core 自動テストの提案

a11y チェックでCritical項目が検出された場合、自動テストの導入を提案する：

```
💡 提案: このコンポーネントに axe-core テストを追加すると、
   a11y 違反を CI で自動検出できます。

   import { axe, toHaveNoViolations } from 'jest-axe';
   expect.extend(toHaveNoViolations);

   const { container } = render(<YourComponent />);
   expect(await axe(container)).toHaveNoViolations();
```

### Step 4: ビジュアルデザインチェック

#### スペーシング（8ptグリッド）
```
❌ padding: 13px 17px;
✅ padding: 16px 24px;  /* 8の倍数 */
```

#### コントラスト比
| 対象 | 最小比 |
|------|--------|
| UI要素（アイコン、ボーダー） | 3:1 |
| 大きいテキスト（18px以上） | 3:1 |
| 小さいテキスト | 4.5:1 |

#### タッチターゲット
- 最小サイズ: **48×48px**
- 隣接ターゲット間に十分なスペース

#### ボタン階層
- プライマリボタンは1画面に**1つのみ**

#### タイポグラフィ
- 見出しの `letter-spacing: -0.02em`
- サイズジャンプ **3x以上**（h1: 48px / body: 16px）
- ジェネリックフォント（Inter, Roboto, Arial）を避ける

#### 視覚的階層
- アライメントの一貫性
- 重要な要素はサイズ・色・位置で強調

### Step 5: 結果レポート

優先度別に分類して出力:

```markdown
## UI Check Summary

### 🔴 Critical（必須修正）
- src/Button.tsx:15 - Missing aria-label on icon button
- src/Form.tsx:42 - コントラスト比が4.5:1未満

### 🟡 Important（推奨修正）
- src/List.tsx:100 - 50件以上のリストが仮想化されていない
- src/Card.tsx:25 - 8ptグリッドに準拠していないスペーシング

### 🟢 Suggestions（検討）
- src/Header.tsx:10 - 見出しのletter-spacingを狭くすると見栄え向上

### ✅ 良い点
- アクセシビリティ属性が適切
- 一貫したコンポーネント設計
```

---

## クイックリファレンス

### 推奨フォント（ジェネリック回避）

| カテゴリ | フォント |
|---------|---------|
| コード風 | JetBrains Mono, Fira Code, Space Grotesk |
| エディトリアル | Playfair Display, Crimson Pro |
| テクニカル | IBM Plex family, Source Sans 3 |

### 8ptグリッド値
`8, 16, 24, 32, 40, 48, 56, 64...`

### 背景のベストプラクティス
ソリッドカラーを避け、レイヤードグラデーションを検討:
```css
background:
  radial-gradient(circle at 20% 50%, rgba(0, 102, 255, 0.1) 0%, transparent 50%),
  radial-gradient(circle at 80% 50%, rgba(255, 51, 102, 0.1) 0%, transparent 50%),
  #0a0a0a;
```

---

## Tips

- **Critical優先**: アクセシビリティとコントラストは最優先で修正
- **段階的改善**: 一度に全て修正しようとしない
- **共通コンポーネント先**: Button, Input 等を先に修正すると効率的
