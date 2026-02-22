---
description: "Use when forming Agent Teams for design decisions, architecture reviews, or multi-perspective analysis"
---

# Agent Team 編成パターン

Claude Code の Agent Team を組む際の選択指針。コストが高いため、不可逆な設計判断や多角的検証が必要な場面に限定する。

## パターン選択

| 場面 | パターン | メンバー |
|------|---------|---------|
| **実装の並列化** | 役割ベース | Frontend / Backend / QA（技術領域で分担） |
| **機能設計（Plan）** | ステークホルダーベース | Engineer / User / Business（利害関係者の視点） |
| **不可逆な技術選択** | 思考スタイルベース | Pragmatist / Skeptic / Idealist / Connector（生産的摩擦） |

## 運用

- 各メンバーには極端な立場を徹底させ、ファシリテーター（リーダー）が合成する
- 結論を出すのはチームではなくファシリテーター
- 議論の結果は ADR として記録する

参考: [Agent Teamを「4つの性格」で組む](https://zenn.dev/happy_elements/articles/d01195392ceb10)
