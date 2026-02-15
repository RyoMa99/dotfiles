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