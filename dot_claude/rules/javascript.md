# JavaScript / TypeScript

JS/TS プロジェクト共通のルール。

---

## パッケージマネージャ

- **pnpm** を標準とする（npm ではなく pnpm を使用）
- `npm install` / `npm run` ではなく `pnpm install` / `pnpm <script>` を使う
- 新規プロジェクトでは `package.json` に `packageManager` フィールドを設定する