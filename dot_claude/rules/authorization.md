# 認可設計

認可（Authorization）の設計判断に必要な知見。モデル選定 → アーキテクチャ → 層配置 → DDD/CQRS 統合の順で判断する。

関連: `layered-architecture.md`（層の責務）、`domain-modeling` スキル（Specification、DDD Trilemma）

---

## 認可の三要素

すべての認可判断は以下の3つで構成される。

- **Actor（誰が）**: リクエスト元の識別（認証で確定済み）
- **Action（何を）**: 実行しようとする操作
- **Resource（何に）**: 対象となるリソース

---

## Step 1: 認可モデルの選定

| モデル | 判定基準 | 柔軟性 | 適用場面 |
|---|---|---|---|
| **RBAC** | ロール（役割）に紐づく権限の束 | 中 | 業務システム、管理画面 |
| **ABAC** | 主体・リソース・環境の属性で動的判定 | 高 | 部署制限、時間帯制限 |
| **ReBAC** | エンティティ間の関係性グラフ | 最高 | 共有、階層組織、フォルダ継承 |

> RBAC は ABAC の特殊ケース（属性が「ロール」1つだけの ABAC）。実務では **RBAC + ABAC のハイブリッド**をベースに、必要に応じて ReBAC を検討する。

### 選定基準

```
権限の判定は何で決まるか？
    │
    ├─ 固定的な役割だけ → RBAC
    │   例: Admin / Editor / Viewer の3ロール
    │
    ├─ 役割 + 属性条件 → RBAC + ABAC
    │   例: 「自部署のデータのみ」「営業時間内のみ」
    │
    └─ エンティティ間の関係（共有、階層、所有） → + ReBAC
        例: 「フォルダ共有者はファイルも閲覧可」
```

### 注意: ロール爆発

RBAC でロールが増殖すると実質 ACL と変わらなくなる。「○○部の△△担当で××プロジェクトの...」のようなロールが出てきたら ABAC への移行を検討する。

---

## Step 2: 認可アーキテクチャ（XACML 参照アーキテクチャ）

認可モデルに依存しない汎用的なアーキテクチャ。4つの役割に分離する。

| コンポーネント | 責務 | 例 |
|---|---|---|
| **PAP**（Policy Administration） | ポリシーの定義・管理 | ロール定義、ポリシーファイル |
| **PIP**（Policy Information） | 判断に必要な属性情報の取得 | ユーザーの部署、リソースの状態 |
| **PDP**（Policy Decision） | 「許可 or 拒否」の判定ロジック | Specification、OPA |
| **PEP**（Policy Enforcement） | 判定結果の適用 | 403 返却、WHERE 句追加 |

> **最重要: PDP（判断）と PEP（適用）の分離。** 判断ロジックを1箇所にまとめ、適用箇所は複数持てる。

### 配置パターン

| パターン | 構造 | 適用場面 |
|---|---|---|
| **Decentralized** | 各サービスが PDP + PEP + 認可データを保有 | モノリス、単一サービス |
| **Centralized** | 全サービスが1つの認可サービス（PDP）に委譲 | 大規模マイクロサービス |
| **Hybrid** | 基本は各サービスで判定、必要時に委譲 | 少数のマイクロサービス |

Decentralized が最もシンプルで、データがローカルにあるため高速。サービス数が増えてルールの一貫性が必要になったら Centralized に移行する。

> ReBAC の関係性グラフ探索は計算コストが高いため、実質的に Centralized な専用エンジン（OpenFGA、AWS Verified Permissions 等）が必要になる。モデルの複雑さがアーキテクチャの選択を制約する。

---

## Step 3: DDD / レイヤーにおける PDP の配置

認可の PDP（判断）をどの層に置くかは、認可ルールの性質で決まる。

| 認可の性質 | PDP の配置 | 認可モデル | 実装パターン |
|---|---|---|---|
| 静的なロール判定 | アプリケーション層 | RBAC | `@PreAuthorize` 等の宣言的チェック |
| ドメイン状態に依存 | ドメイン層 | ABAC | Specification パターン |
| 複雑・横断的 | 独立した境界づけられたコンテキスト | ReBAC | 専用認可サービス（OPA、OpenFGA） |

### 認可とドメインルールの判別

Entity に置くべきか AuthPolicy に置くべきかは、Actor への依存で判断する。

```
この制約は Actor を取り除いても成立するか？
    │
    ├─ Yes → Entity のドメインルール（不変条件）
    │   例: 「キャンセル済みは編集不可」（誰であっても）
    │   → Entity 自身が enforce する（require / throw）
    │
    └─ No → AuthPolicy（アクセス制御）
        例: 「手配権限がある人だけ編集可」（Actor 依存）
        → PDP（Policy / Gate）に配置
```

Entity にアクセス制御を持たせない理由:
- **SRP 違反**: ビジネスルールと権限体系は変更理由が異なる（`robust-code.md`「変更のタイミングと理由」参照）
- **Actor への依存**: ドメインモデルが権限フラグの構造を知る必要が生じる
- **テストの肥大化**: Entity のテストに権限パターンのテストが混入する

### DDD Trilemma との関係

ドメイン層に Specification として認可を置く場合、Trilemma が適用される（`domain-modeling` スキル参照）。

- **アプローチ C（推奨）**: PIP（属性取得）はアプリケーション層、PDP（判断）はドメイン層。属性を引数で受け取り純粋に判定
- **アプローチ B**: ドメインサービスに Repository を注入して属性を取得。完全性は高いが純粋性を犠牲

### PEP の適用箇所

| 適用箇所 | 判断内容 | 粒度 |
|---|---|---|
| Proxy / Router | トークンベースのルートアクセス制御 | 粗い |
| Controller / UseCase | ロール・属性ベースの操作権限 | 中 |
| データアクセス層 | WHERE 句でのデータフィルタリング | 細かい |

通常は Controller で粗い PEP、データアクセス層で細かい PEP を配置する。

---

## Step 4: CQRS における認可の設計

コマンド側とクエリ側で認可の目的が異なる。

| | コマンド側 | クエリ側 |
|---|---|---|
| 目的 | 「この操作を実行してよいか？」 | 「このデータを見てよいか？」 |
| XACML | PDP（判定） | PEP（フィルタ適用） |
| Specification | **検証**用途（`isSatisfiedBy`） | **選択**用途（WHERE 句導出） |
| エラー | 403 Forbidden（明示的な拒否） | データが見えない（暗黙のフィルタ） |

### 二重管理問題の判断

```
コマンド側とクエリ側で同じ認可ルールか？
    │
    ├─ 異なる（操作権限 vs データ可視性）
    │   → 別の関心事として個別設計。二重管理ではない
    │
    └─ 同じ（「自部署のデータのみ」等）
        ├─ Specification の検証/選択 両用途で統一可能？
        │   ├─ Yes → JPA Specification / QueryDSL で WHERE 句自動生成
        │   └─ No  → AccessScope 等の共通定義から両側に導出
        └─ DB レベルで制御可能？
            → Row-Level Security（PostgreSQL RLS 等）
```

> Evans 原典: Specification は「検証」「選択」「要求に応じた構築」の3用途を持つ。同一の Specification からコマンド側の判定とクエリ側の WHERE 句を導出するのは DDD の思想に合致する。

---

## Step 5: 認可の構造的強制

認可チェックの「呼び忘れ」をどの強度で防ぐかは、呼び忘れ時の被害で判断する。

```
認可の呼び忘れが起きた時の被害は？
    │
    ├─ 致命的（決済、個人情報漏洩、データ破壊）
    │   → 型で構造的に強制する
    │   → Authorized<T> 型（認可済みリソースの型）を UseCase の引数に要求
    │   → ドメインモデルへの侵入はセキュリティとのトレードオフで許容
    │
    └─ 中程度（業務データの不整合、権限逸脱）
        → Authorized wrapper + テストで十分
        → ドメインモデルの純粋性を優先
```

### 強制レベル

| レベル | 手法 | 忘れた時 | 導入コスト |
|--------|------|---------|-----------|
| 0 | 実装者に依存 | 気づかない | なし |
| 1 | アーキテクチャテスト | CI で失敗 | 低 |
| 2 | Authorized<T> 型（Parse, don't Validate の認可版） | コンパイルエラー | 中 |
| 3 | Context Receivers / Decorator + DI | そもそも迂回不可 | 高 |

> レベル 2 の Authorized<T> は `robust-code.md`「Parse, don't Validate」の認可への適用。認可が通ったという事実を型に変換し、後続処理は型を信頼する。

---

## 参考資料

- [Authorization Academy（Oso）](https://www.osohq.com/academy) — 認可モデルとアーキテクチャの体系的解説
- [XACML 参照アーキテクチャ](https://kenfdev.hateblo.jp/entry/2020/01/13/115032) — PAP/PIP/PDP/PEP の4役割分離
- [アプリケーション権限モデルの比較](https://zenn.dev/penysho/articles/4d1ad3f5f5ed7d) — ACL/RBAC/ABAC/ReBAC の選定基準
- Khorikov - DDD Trilemma — 認可 Specification の配置と純粋性のトレードオフ
- Evans - Domain-Driven Design — Specification パターンの検証/選択/構築の3用途
