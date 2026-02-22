---
globs: ["*.js", "*.jsx", "*.ts", "*.tsx", "package.json", "pnpm-workspace.yaml"]
---

# JavaScript / TypeScript エコシステム

JS/TS プロジェクト共通のパッケージ管理のルール。
TypeScript の言語固有の知見（型システム、コンパイラ設定、型パターン）は `typescript.md` を参照。

---

## パッケージマネージャ

- **pnpm** を標準とする（npm ではなく pnpm を使用）
- `npm install` / `npm run` ではなく `pnpm install` / `pnpm run <script>` を使う
- 新規プロジェクトでは `package.json` に `packageManager` フィールドを設定する

