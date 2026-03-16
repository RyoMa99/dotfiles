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

### コマンド側とクエリ側のルール関係

コマンド側（操作権限）とクエリ側（可視性）の認可ルールの関係を見極め、適切に統合または分離する。

```
コマンド側とクエリ側のルールの関係は？
    │
    ├─ 同一（同じ述語で判定）
    │   例: 「自部署のデータのみ」が編集にも一覧にも適用
    │   → 1つの Specification から検証/選択の両用途に導出
    │       ├─ ORM あり → JPA Specification / QueryDSL で WHERE 句自動生成
    │       ├─ ORM なし → AccessScope 等の共通定義から両側に導出
    │       └─ DB レベル → Row-Level Security（PostgreSQL RLS 等）
    │
    ├─ 包含関係（可視性 ⊇ 操作権限）← 実務で最も多い
    │   例: 「関連部署のイベントは見えるが、編集は自部署のみ」
    │   → 狭い方（操作権限）から広い方（可視性）を導出する構造にする
    │   → 包含関係が壊れると「操作できるが見えない」矛盾が生じるため
    │
    └─ 独立（変更が互いに影響しない）
        例: 操作権限は「手配権限フラグ」、可視性は「部署」で判定
        → 別の関心事として個別設計。無理に統合しない
```

**見分け方**: コマンド側のルールを変えたとき、クエリ側も必ず同時に変わるか？ → Yes なら同一、No なら独立。片方が変わったらもう片方も追随すべきなら包含関係。

#### 包含関係の実装パターン

```kotlin
// 狭い方（操作権限）から広い方（可視性）を導出
class EventAccessScope(val actor: ActorContext) {
    // 操作可能な範囲（狭い）
    fun editableFilter(): Predicate =
        deptEquals(actor.deptId).and(hasPermission(Permission.TEHAI))

    // 可視範囲（広い）= 操作可能範囲 + 閲覧のみの範囲
    fun visibleFilter(): Predicate =
        editableFilter().or(relatedDepts(actor.deptId))
}
```

または AccessLevel で統合:

```kotlin
enum class AccessLevel { NONE, VIEW, EDIT }

class EventAccessResolver(val actor: ActorContext) {
    fun resolve(event: Event): AccessLevel = when {
        event.deptId == actor.deptId && actor.permission.tehai -> EDIT
        event.deptId in actor.relatedDeptIds -> VIEW
        else -> NONE
    }
}
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

### コマンド側（書き込み）の認可強制

#### 実務での選定

```
コマンド側の認可をどう強制するか？
    │
    ├─ フレームワークの宣言的認可がある（Spring Security, NestJS Guards 等）
    │   → アノテーション / デコレータ方式（最も採用が多い）
    │   → ArchUnit で「アノテーション付け忘れ」を検査して補強
    │
    ├─ CQRS でコマンドバスがある
    │   → コマンドバスの Middleware に認可を組み込む（構造的に迂回不可）
    │
    └─ フレームワーク非依存 / 高リスク
        → Authorized<T> 型 or Policy パターン
```

#### パターン A: アノテーション / デコレータ方式（レベル 1 相当）

実務で最も多い。Spring Security の `@PreAuthorize`、NestJS の `@UseGuards` 等。

```kotlin
// Spring Security
@PreAuthorize("hasRole('EDITOR') and @accessChecker.canEdit(#orderId)")
fun updateOrder(orderId: OrderId, command: UpdateOrderCommand) { ... }
```

**単体では呼び忘れを防げない**（アノテーションの付け忘れは検出されない）。ArchUnit でアノテーションの存在を検査して補強する。

```java
// ArchUnit: Controller の全パブリックメソッドに @PreAuthorize があるか
@Test
void all_controller_methods_should_have_authorization() {
    methods()
        .that().areDeclaredInClassesThat().areAnnotatedWith(RestController.class)
        .and().arePublic()
        .should().beAnnotatedWith(PreAuthorize.class);
}
```

#### パターン B: コマンドバス Middleware（レベル 3 相当）

CQRS 構成でコマンドバスを使っている場合、Middleware として認可を挟む。コマンドが必ずバスを経由するなら構造的に迂回不可。

```kotlin
// コマンドに必要な権限を宣言
@RequiresPermission(Permission.ORDER_EDIT)
data class UpdateOrderCommand(val orderId: OrderId, val items: List<Item>)

// Middleware がコマンド実行前に自動チェック
class AuthorizationMiddleware(private val pdp: PolicyDecisionPoint) : CommandMiddleware {
    override fun <T> handle(command: T, next: (T) -> Any): Any {
        val required = command::class.findAnnotation<RequiresPermission>()
            ?: throw IllegalStateException("Permission not declared on ${command::class}")
        pdp.authorize(currentActor(), required.value)
        return next(command)
    }
}
```

アノテーション未宣言をランタイムエラーではなく ArchUnit で検査すればさらに堅牢。

#### パターン C: Policy パターン（レベル 2 相当）

Laravel の Policy / Rails の Pundit に代表される。リソースごとにポリシークラスを定義し、Controller から明示的に呼ぶ。

```ruby
# Rails + Pundit
class OrdersController < ApplicationController
  def update
    order = Order.find(params[:id])
    authorize order  # ← 呼び忘れると Pundit::AuthorizationNotPerformedError
    order.update!(order_params)
  end
end

# ApplicationController で after_action :verify_authorized を設定
# → authorize を呼ばなかった場合にエラー（フレームワークレベルの強制）
```

Pundit の `verify_authorized` は「呼び忘れをフレームワークが検出する」仕組みで、レベル 1〜2 の中間に位置する。

#### パターン D: Authorized<T> 型（レベル 2 相当）

理論的には最も型安全だが、実務での採用は多くない。既存コードベースへの導入コストが高いため、新規プロジェクトまたは高リスク領域に限定して適用するのが現実的。

```kotlin
// 認可済みを型で表現
class Authorized<T> private constructor(val value: T) {
    companion object {
        fun <T> of(value: T, actor: ActorContext, pdp: PolicyDecisionPoint): Authorized<T> {
            pdp.authorize(actor, value)
            return Authorized(value)
        }
    }
}

// UseCase は Authorized<Order> しか受け取らない
class UpdateOrderUseCase {
    fun execute(order: Authorized<Order>, command: UpdateOrderCommand) { ... }
}
```

#### 見落とされやすい抜け穴

| 抜け穴 | 問題 | 対策 |
|--------|------|------|
| **複数エントリポイント** | REST は守っているが GraphQL / gRPC は無防備 | 認可を UseCase 層に配置し、エントリポイントに依存しない構造にする |
| **内部サービス間呼び出し** | 内部だからと認可をスキップ | SystemContext 型を要求。信頼された呼び出し元でも認可パスを通す |
| **イベントハンドラ / Saga** | イベント起因の副作用に認可がない | イベントに発行者の ActorContext を含め、ハンドラ側で再検証する |
| **Bulk 操作** | 単体は守っているがバッチ更新は無防備 | Bulk API にも同じ認可パスを適用。ループ内で個別チェックかバッチ用 Policy を用意 |
| **PATCH / 部分更新** | フィールドごとの権限差異を見落とす | 更新対象フィールドを Permission に含める（field-level authorization） |

> 実務で最も事故率が高いのは**複数エントリポイント**の問題。REST Controller にだけ `@PreAuthorize` を付けて GraphQL Resolver には付け忘れるパターン。認可を Controller ではなく UseCase 層に配置することで、エントリポイント増加時にも漏れない。

### レベル 1: アーキテクチャテストの実装

#### ツール選択

| 言語 | ツール | 特徴 |
|------|--------|------|
| Java/Kotlin | **ArchUnit** | クラス・メソッドレベルの依存・呼び出し検査 |
| .NET | **NetArchTest** | ArchUnit の .NET 版 |
| TypeScript | **dependency-cruiser** | モジュール間の依存方向の検査 |

#### 検査パターン

1. **UseCase が認可チェックを呼んでいるか**: UseCase のパブリックメソッドが必ず認可メソッド（authorize / checkPermission 等）を呼び出していることを検証
2. **Domain 層が認可モジュールに依存しないか**: PDP の配置（Step 3）に違反する依存がないことを検証
3. **Repository の書き込みに Authorized<T> を要求しているか**（レベル 1 + 2 の併用）: save / update / delete メソッドの引数に Authorized 型が含まれることを検証

#### 運用上の注意

- アーキテクチャテストは**呼び忘れ防止**には有効だが、**認可ロジックの正しさ**（正しい権限を検査しているか）は別のテストで担保する
- 偽陽性を抑えるため、テスト用ヘルパーや内部ユーティリティの除外ルールを整備する
- レベル 1 単体より **レベル 1 + レベル 2 の併用**が効果的（構造検査 + 型安全の二重保証）

### クエリ側（読み取り）の認可強制

コマンド側は `save(authorized: Authorized<Order>)` のように引数で強制できるが、クエリ側は `findAll()` のように引数なしで呼べてしまう。クエリ側には別の強制パターンが必要。

#### システム性質別の選定

```
どのシステムか？
    │
    ├─ マルチテナント SaaS（テナント間漏洩は致命的）
    │   → ORM グローバルフィルタ + RLS の二重構造
    │   → ORM 側で通常クエリを保護、RLS で直接 SQL も防ぐ
    │
    ├─ 業務システム（部署間・ロール別の可視性制御）
    │   → AccessScope 必須引数 + ArchUnit 検査
    │
    └─ 小規模 / 単一テナント
        → クエリサービスへのフィルタ組み込み + テスト
```

#### パターン A: AccessScope 必須引数（レベル 2 相当）

Repository のクエリメソッドにフィルタなしの署名を公開しない。AccessScope が Authorized<T> のクエリ版。

```kotlin
interface OrderRepository {
    // findAll() は存在しない
    fun findAll(scope: AccessScope): List<Order>
    fun findById(id: OrderId, scope: AccessScope): Order?
}
```

ArchUnit で全パブリックメソッドが `AccessScope` 引数を持つことを検査する。

#### パターン B: ORM グローバルフィルタ + RLS（レベル 3 相当）

マルチテナント SaaS の事実上の標準。ORM のフィルタでアプリ層を保護し、RLS でバイパスを防ぐ。

```kotlin
// Hibernate @Filter: リクエストごとにテナントIDを自動付与
@Entity
@FilterDef(name = "tenantFilter", parameters = [ParamDef(name = "tenantId", type = "string")])
@Filter(name = "tenantFilter", condition = "tenant_id = :tenantId")
class Order { ... }
```

```sql
-- PostgreSQL RLS: DB レベルで迂回不可能
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY orders_dept_isolation ON orders
    USING (tenant_id = current_setting('app.current_tenant_id'));
```

RLS は `current_setting` 未設定時にフェイルクローズ（拒否）する設計にする。コネクション取得時のインターセプタで設定を強制する。

#### パターン C: クエリサービスにフィルタを組み込む（レベル 2 相当）

```kotlin
class OrderQueryService(
    private val orderDao: OrderDao,
    private val actor: ActorContext  // DI で注入
) {
    fun search(criteria: SearchCriteria): List<OrderSummary> {
        val scope = AccessScope.of(actor)
        return orderDao.search(criteria, scope)
    }
}
```

#### 見落とされやすい抜け穴

正規のクエリパスを守っても、別経路が無防備では意味がない。

| 抜け穴 | 対策 |
|--------|------|
| **管理画面** | 管理用 Repository を分離し、監査ログを必須にする |
| **バッチ処理** | SystemContext 型を要求。通常リクエストからは生成不可 |
| **CSV エクスポート** | クエリと同じ AccessScope を通す。別経路を作らない |
| **ネストされたリレーション** | DataLoader レベルでフィルタ。親の認可だけでは子の可視性は保証されない |
| **キャッシュ** | テナントID / ユーザーID をキャッシュキーに含める |

ArchUnit の検査対象にこれらの別経路を含めることが重要。

---

## 参考資料

- [Authorization Academy（Oso）](https://www.osohq.com/academy) — 認可モデルとアーキテクチャの体系的解説
- [XACML 参照アーキテクチャ](https://kenfdev.hateblo.jp/entry/2020/01/13/115032) — PAP/PIP/PDP/PEP の4役割分離
- [アプリケーション権限モデルの比較](https://zenn.dev/penysho/articles/4d1ad3f5f5ed7d) — ACL/RBAC/ABAC/ReBAC の選定基準
- Khorikov - DDD Trilemma — 認可 Specification の配置と純粋性のトレードオフ
- Evans - Domain-Driven Design — Specification パターンの検証/選択/構築の3用途
