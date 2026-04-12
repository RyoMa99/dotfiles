---
name: db-design
description: テーブル設計のレビュー・ガイドスキル。新規テーブル設計、マイグレーション作成、既存スキーマのレビュー時に使う。「テーブル設計」「DB設計」「スキーマ設計」「カラム追加」「ステータス管理」「状態遷移」「マイグレーション」などで起動する。テーブルにステータスカラムを追加しようとしている場面や、複数の状態を1テーブルで管理しようとしている場面では必ず使うこと。
---

# DB 設計ガイド

テーブル設計時のステータス管理に関する原則とチェックリスト。

---

## このスキルの使い方

このスキルはステータス設計に関するガイドラインを提供する。テーブル設計全体（正規化、明細テーブル、インデックス戦略など）を網羅するものではない。

**使い分け:**

| 場面 | このスキルの役割 |
|------|----------------|
| 既存テーブルへのステータスカラム追加 | **主役**。アンチパターンを検出し、代替設計を提案する |
| 新規テーブル設計 | **補助**。ステータス部分の設計に5ステップを適用する。明細テーブル・リレーション設計など他の側面は通常の設計判断で進める |
| 既存スキーマのレビュー | **チェックリスト**として活用する |

新規設計時は、5ステップをステータス設計の思考フレームワークとして使いつつ、テーブル全体の設計（明細テーブル、マスタテーブル、リレーション）は要件に基づいて自由に構成すること。スキルに書いていない要素を追加することを躊躇しない。

---

## ステータス設計の5ステップ

ステータスカラムをテーブルに追加する前に、以下の順序で考える。
カラムから考え始めると「何を保存するか」に引きずられ、ステータスが混在する設計になる。

### Step 1: イベントを列挙する

システムで発生するイベント（出来事）を先に洗い出す。

```
例: 受注システム
- 注文が作成された
- 支払いが完了した
- 出荷が指示された
- 出荷が完了した
- キャンセルが申請された
- 返品が受理された
```

「何が起きるか」を先に定義することで、テーブルに何を記録すべきかが明確になる。

### Step 2: リソースとイベントを分離する

リソース（モノ）とイベント（コト）を別テーブルにする。

| 分類 | 例 | テーブルの性質 |
|------|-----|---------------|
| リソース | 注文、商品、ユーザー | 現在の状態を持つ。UPDATE される |
| イベント | 注文作成、支払完了、出荷 | 発生した事実を記録する。INSERT only |

```sql
-- BAD: リソーステーブルにイベント情報が混在
CREATE TABLE orders (
  id BIGINT PRIMARY KEY,
  status VARCHAR(20),           -- 注文ステータス
  payment_status VARCHAR(20),   -- 支払いステータス
  shipping_status VARCHAR(20),  -- 出荷ステータス
  cancelled_at TIMESTAMP,
  refunded_at TIMESTAMP
);

-- GOOD: リソースとイベントを分離
CREATE TABLE orders (
  id BIGINT PRIMARY KEY,
  status VARCHAR(20)  -- 注文全体の現在状態のみ
);

CREATE TABLE order_events (
  id BIGINT PRIMARY KEY,
  order_id BIGINT REFERENCES orders(id),
  event_type VARCHAR(50),
  occurred_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

**判断基準**: そのカラムは「現在の状態」か「過去に起きた事実」か？
- 現在の状態 → リソーステーブルのカラム
- 過去の事実 → イベントテーブルの行

**イベントテーブルの分割判断**: イベントの種類によってペイロード（付随する情報）が大きく異なる場合は、汎用の events テーブルよりも目的別テーブル（reviews, transitions 等）に分けたほうがスキーマが明確になる。

### Step 3: ステータス遷移図を定義する

テーブル設計の前に、状態遷移図を書く。遷移図がないまま実装すると、不正な遷移を防げない。

```
[created] → [paid] → [shipped] → [delivered]
    ↓          ↓
[cancelled] [refunded]
```

遷移図から以下を導出する:
- **許可される遷移**: アプリケーション層でバリデーションする
- **終端状態**: それ以降の遷移がない状態（delivered, cancelled）
- **分岐点**: 複数の遷移先がある状態（paid → shipped / refunded）

遷移が複雑になる場合（5状態以上、条件付き遷移が多い）は、ステータスの粒度が粗すぎる兆候。Step 2 に戻り、イベントの分解を見直す。

### Step 4: 外部コードと内部ステータスを分離する

外部システム（決済API、物流API等）のステータスコードを内部のステータスとして直接使わない。

```sql
-- BAD: 外部APIのコードをそのまま保存
CREATE TABLE payments (
  id BIGINT PRIMARY KEY,
  stripe_status VARCHAR(50)  -- 'succeeded', 'pending', 'failed'...Stripe依存
);

-- GOOD: 内部ステータスと外部コードを分離
CREATE TABLE payments (
  id BIGINT PRIMARY KEY,
  status VARCHAR(20)  -- 内部定義: 'completed', 'pending', 'failed'
);

CREATE TABLE payment_gateway_responses (
  id BIGINT PRIMARY KEY,
  payment_id BIGINT REFERENCES payments(id),
  provider VARCHAR(30),
  provider_status VARCHAR(50),  -- 外部APIのコード
  raw_response JSONB,
  received_at TIMESTAMP
);
```

**理由**:
- 外部APIの仕様変更で内部ロジックが壊れる
- 複数の外部システムを使う場合にステータス体系が混在する
- 外部コードの意味が不明確になる（数値コードの場合は特に）

### Step 5: 外部区分値を導入する際は意味も持ち込む

外部システムの区分値（コードマスタ）を取り込む場合、コード値だけでなく意味（名称・説明）も管理する。

```sql
-- BAD: コード値だけ保存、意味は外部システム参照
ALTER TABLE shipments ADD COLUMN carrier_status INT;  -- 1? 2? 3?

-- GOOD: 意味も一緒に管理
CREATE TABLE carrier_status_codes (
  code INT PRIMARY KEY,
  name VARCHAR(100),
  description TEXT,
  provider VARCHAR(30),
  updated_at TIMESTAMP
);
```

---

## ステータス設計のアンチパターン

### 1. Boolean フラグの増殖

```sql
-- BAD: フラグで状態を表現
CREATE TABLE tasks (
  id BIGINT PRIMARY KEY,
  is_started BOOLEAN DEFAULT FALSE,
  is_completed BOOLEAN DEFAULT FALSE,
  is_cancelled BOOLEAN DEFAULT FALSE
  -- is_started=true AND is_cancelled=true は何？
);

-- GOOD: 排他的な状態を1カラムで表現
CREATE TABLE tasks (
  id BIGINT PRIMARY KEY,
  status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled'))
);
```

Boolean フラグは2個までなら許容できるが、3個以上は組み合わせ爆発が起きる（2^3 = 8 通り、大半が不正状態）。

**ただし**: 各フラグが本当に独立した軸（ステータスではなく属性）である場合は Boolean で正しい。例: `is_featured`（おすすめ表示）と `is_premium`（課金コンテンツ）は独立した属性であり、ステータスではない。

### 2. ステータスカラムの横増殖

1つのテーブルに複数の `*_status` カラムがある場合、テーブルの責務が大きすぎる兆候。

```sql
-- 黄色信号: 2つ以上のステータスカラム
CREATE TABLE orders (
  order_status VARCHAR(20),
  payment_status VARCHAR(20),
  shipping_status VARCHAR(20),
  review_status VARCHAR(20)
);
```

対処:
- 各ステータスが独立したライフサイクルを持つなら、テーブルを分割する
- 従属関係があるなら（支払い完了 → 出荷可能）、イベントテーブルで遷移を管理する

### 3. NULL でステータスを表現する

```sql
-- BAD: NULL が「未処理」を意味する暗黙のルール
CREATE TABLE applications (
  approved_at TIMESTAMP,  -- NULL = 未審査 / NOT NULL = 承認済み
  rejected_at TIMESTAMP   -- NULL = 未却下 / NOT NULL = 却下済み
);

-- GOOD: 明示的なステータスカラム + タイムスタンプ
CREATE TABLE applications (
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  decided_at TIMESTAMP  -- 承認/却下が確定した日時
);
```

---

## 設計の出力に含めるべきもの

このスキルを使って設計を出力する際、以下を含めると設計の意図が伝わりやすい。

1. **遷移図**（テキストまたは Mermaid）— 状態と遷移の全体像
2. **DDL** — CHECK 制約、インデックスを含む CREATE TABLE 文
3. **設計判断の根拠** — なぜこのテーブル構成にしたか（特に分割・統合の判断）
4. **遷移制約の実装方針** — アプリケーション層での実装例（許可される遷移のマップ）

---

## チェックリスト

テーブル設計のレビュー時に確認する。

- [ ] ステータスカラムを追加する前に、イベント列挙と遷移図の定義を行ったか
- [ ] リソース（現在の状態）とイベント（発生した事実）が分離されているか
- [ ] 1テーブルに2つ以上のステータスカラムが混在していないか
- [ ] Boolean フラグが3つ以上並んでいないか（独立属性でない場合）
- [ ] 外部システムのコードを内部ステータスとして直接使っていないか
- [ ] NULL にビジネス上の意味を持たせていないか
- [ ] ステータス遷移の制約がアプリケーション層で実装されているか
- [ ] イベントテーブルは INSERT only（UPDATE しない）設計になっているか
