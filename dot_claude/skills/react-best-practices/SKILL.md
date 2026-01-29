---
name: react-best-practices
description: React and Next.js performance optimization guidelines from Vercel Engineering. Use when writing, reviewing, or refactoring React/Next.js code to ensure optimal performance patterns.
---

# React Best Practices

**Version 1.0.0** — Vercel Engineering

React/Next.jsアプリケーションの包括的なパフォーマンス最適化ガイド。8カテゴリ・40以上のルールを優先度別に整理。

## When to Use This Skill

Trigger when:
- React/Next.jsコンポーネントの作成・修正
- パフォーマンス最適化のレビュー
- データフェッチングパターンの実装
- バンドルサイズの最適化
- 「パフォーマンスを改善して」「最適化して」といった依頼

## カテゴリ概要（優先度順）

| 優先度 | カテゴリ | 内容 |
|--------|----------|------|
| **CRITICAL** | 1. Eliminating Waterfalls | 直列awaitの排除 |
| **CRITICAL** | 2. Bundle Size Optimization | バンドルサイズ削減 |
| **HIGH** | 3. Server-Side Performance | RSC・キャッシュ最適化 |
| **MEDIUM-HIGH** | 4. Client-Side Data Fetching | SWR・イベントリスナー |
| **MEDIUM** | 5. Re-render Optimization | 再レンダリング削減 |
| **MEDIUM** | 6. Rendering Performance | Hydration・SVG最適化 |
| **LOW-MEDIUM** | 7. JavaScript Performance | ループ・配列最適化 |
| **LOW** | 8. Advanced Patterns | Refs・コールバック |

## クイックリファレンス

### CRITICAL: 必ず確認すべきルール

**Waterfalls排除:**
- `Promise.all()` で独立した処理を並列化
- `await` は必要な分岐でのみ実行
- Suspense境界を戦略的に配置

**バンドルサイズ:**
- Barrel file (`index.ts`) からの直接インポートを避ける
- 重いコンポーネントは `dynamic()` でインポート
- サードパーティライブラリは条件付きロード

### HIGH: サーバーサイド

- `React.cache()` でリクエスト内重複排除
- LRUキャッシュでリクエスト間キャッシュ
- RSC境界でのシリアライズを最小化

### MEDIUM: クライアントサイド

- SWRで自動重複排除
- `useTransition` で非緊急更新を分離
- 静的JSXをコンポーネント外に巻き上げ

## 詳細ドキュメント

完全なルールと実装例は参照ファイルを確認:

- [full-reference.md](full-reference.md) — 全40+ルールの詳細と実装例

## 適用時の原則

1. **優先度順に対応** — CRITICALから着手
2. **計測してから最適化** — 推測で最適化しない
3. **シンプルさを維持** — 過度な最適化は避ける
