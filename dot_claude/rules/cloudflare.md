# Cloudflare Workers / D1

Cloudflare プラットフォーム固有の知見。

---

## D1 テスト基盤（Vitest + @cloudflare/vitest-pool-workers）

D1 を使うテストでは、マイグレーションを自動適用する基盤が必要。

### セットアップ手順

1. `vitest.config.ts` で `readD1Migrations` を使いマイグレーションを読み込む
2. `miniflare.bindings.TEST_MIGRATIONS` に注入する
3. `setupFiles` で `applyD1Migrations` を実行する
4. `test/env.d.ts` で `ProvidedEnv` を拡張する

```typescript
// vitest.config.ts
import { defineWorkersConfig, readD1Migrations } from "@cloudflare/vitest-pool-workers/config";

export default defineWorkersConfig(async () => {
  const migrations = await readD1Migrations("./migrations");
  return {
    test: {
      setupFiles: ["./test/apply-migrations.ts"],
      poolOptions: {
        workers: {
          wrangler: { configPath: "./wrangler.toml" },
          miniflare: {
            bindings: { TEST_MIGRATIONS: migrations },
          },
        },
      },
    },
  };
});
```

```typescript
// test/apply-migrations.ts
import { applyD1Migrations, env } from "cloudflare:test";
await applyD1Migrations(env.DB, env.TEST_MIGRATIONS);
```

```typescript
// test/env.d.ts
import type { D1Migration } from "@cloudflare/vitest-pool-workers/config";
import type { Bindings } from "../src/types/env";

declare module "cloudflare:test" {
  interface ProvidedEnv extends Bindings {
    TEST_MIGRATIONS: D1Migration[];
  }
}
```

### 注意点

- 各テストファイルは同一の D1 インスタンスを共有するため、テストデータは一意な ID を使い他テストとの干渉を防ぐ
- `tsconfig.json` の `include` に `test/` ディレクトリを追加すること

---

## Workers デプロイ手順

### 初回セットアップ

```bash
# 1. wrangler 認証（ブラウザが開く）
pnpm wrangler login

# 2. D1 データベース作成
pnpm wrangler d1 create <db-name>
# → 返された database_id を wrangler.toml に設定

# 3. マイグレーション適用
pnpm db:migrate:remote

# 4. Secrets 設定（対話的に値を入力）
echo "<token>" | pnpm wrangler secret put AUTH_TOKEN

# 5. デプロイ
pnpm run deploy  # ※ pnpm deploy ではない（pnpm ビルトインと競合）
```

### 注意点

- `pnpm wrangler` 経由で実行する（グローバルインストール不要）
- `wrangler login` はブラウザ認証が必要なため、ユーザーのターミナルで実行
- 非対話環境では `CLOUDFLARE_API_TOKEN` 環境変数で認証可能

---

## Cloudflare Access でパスごとに認証を分ける

同一ドメインでパスごとに異なる認証ポリシー（例: `/` は保護、`/v1/*` はバイパス）を適用する場合、**Application を2つ作成**する。

| Application | ドメイン | パス | ポリシー |
|-------------|---------|------|---------|
| CC Dashboard | `app.workers.dev` | （空） | Allow（メール OTP 等） |
| CC Dashboard API | `app.workers.dev` | `/v1/` | Bypass（Everyone） |

- Bypass ポリシー内にパスフィルタ機能はないため、Application レベルでパスを指定する
- より具体的なパスの Application が優先される
- API 側の認証は Workers アプリケーション内のミドルウェア（Bearer Token 等）で実装する

---

## Hono JSX での SVG レンダリング

Hono JSX の `IntrinsicElements` は `[tagName: string]: Props` のキャッチオールを持つため、`<svg>`, `<rect>`, `<line>`, `<text>`, `<g>` 等の SVG 要素は**型宣言なしでもコンパイル・動作する**。

ただし明示的な `.d.ts`（`declare module "hono/jsx"` で `IntrinsicElements` を拡張）を追加すると、IDE の属性補完が効くようになるため開発体験が向上する。

```typescript
// src/types/jsx-svg.d.ts
declare module "hono/jsx" {
  namespace JSX {
    interface IntrinsicElements {
      svg: { viewBox?: string; width?: string; role?: string; "aria-label"?: string; /* ... */ };
      rect: { x?: number; y?: number; width?: number | string; height?: number | string; fill?: string; rx?: string; /* ... */ };
      // ...他の SVG 要素
    }
  }
}
```

- SSR で SVG を直接生成する場合、クライアント JS や追加依存は不要
- `viewBox` + `width="100%"` でレスポンシブ対応可能

---

## wrangler dev のポート自動フォールバック

`wrangler dev` はデフォルトポート（8787）が使用中の場合、8788, 8789... と自動的に別のポートにフォールバックする。

### よくある原因

- `@cloudflare/vitest-pool-workers` のテスト実行後、workerd プロセスがポートを占有したまま残る
- 複数の Workers プロジェクトを同時に開発している

### 対策

- **stdout の `Ready on http://localhost:{port}` を必ず確認する**（デフォルトポートを仮定しない）
- wrangler の出力を `/dev/null` にリダイレクトしない
- 必要に応じて `lsof -i :8787` で占有プロセスを確認・停止する