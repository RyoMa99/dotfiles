# JavaScript / TypeScript エコシステム

JS/TS プロジェクト共通のツーリング・パッケージ管理のルール。

TypeScript の言語固有の知見（型システム、コンパイラ設定、型パターン）は `typescript.md` を参照。

---

## パッケージマネージャ

- **pnpm** を標準とする（npm ではなく pnpm を使用）
- `npm install` / `npm run` ではなく `pnpm install` / `pnpm <script>` を使う
- 新規プロジェクトでは `package.json` に `packageManager` フィールドを設定する

## pnpm のビルドスクリプト管理

pnpm v10 はセキュリティのため、依存パッケージの `postinstall` 等のビルドスクリプトをデフォルトでブロックする。
許可方法が2つあるが、**`onlyBuiltDependencies`（許可リスト）に統一**する。

| 設定 | 場所 | 意味 |
|------|------|------|
| `pnpm.onlyBuiltDependencies` | `package.json` | **許可リスト**: 指定したパッケージのみビルドスクリプトを実行 |
| `ignoredBuiltDependencies` | `pnpm-workspace.yaml` | **無視リスト**: 指定したパッケージのビルドスクリプトを抑制 |

- `pnpm approve-builds` は `pnpm-workspace.yaml` に `ignoredBuiltDependencies` を生成するが、対話モードが使えない環境では正しく動作しない
- `package.json` の `pnpm.onlyBuiltDependencies` に直接記載する方が確実

## pnpm deploy と pnpm run deploy の違い

`pnpm deploy` は pnpm のビルトインコマンド（workspace からサブセットをデプロイする機能）。
`package.json` の `scripts.deploy` を実行したい場合は `pnpm run deploy` を使う。

```bash
# BAD: pnpm のビルトインコマンドが実行される
pnpm deploy

# GOOD: package.json の scripts.deploy が実行される
pnpm run deploy
```
