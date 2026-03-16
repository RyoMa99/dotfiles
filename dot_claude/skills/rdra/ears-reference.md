# EARS パターン リファレンス

EARS (Easy Approach to Requirements Syntax) — Rolls-Royce 発祥の要件記述パターン。
自然言語の曖昧さを構造化キーワードで制約する軽量アプローチ。

NASA、Airbus、Bosch、Intel、Siemens 等が採用。

---

## 基本構造

```
While [optional precondition], when [optional trigger], the [system name] shall [response]
```

---

## 6パターン

### 1. Ubiquitous（常時有効）

キーワードなし。システムが常に満たすべき制約。

```
The system shall encrypt all stored passwords using bcrypt with a minimum cost factor of 12.
The system shall respond to all API requests within 500ms under normal load.
```

### 2. Event-driven（イベント駆動）

キーワード: **When**

特定のトリガーが発生したときの動作。

```
When the user submits the registration form with valid data,
the system shall create the user account and send a verification email.

When a payment transaction fails,
the system shall log the failure details and notify the operations team.
```

### 3. State-driven（状態駆動）

キーワード: **While**

特定の状態が継続している間の制約。

```
While the system is in maintenance mode,
the system shall reject all write operations and display a maintenance notice.

While a user session is active,
the system shall refresh the authentication token every 15 minutes.
```

### 4. Optional features（オプション機能）

キーワード: **Where**

特定のオプションが有効な場合の動作。

```
Where two-factor authentication is enabled,
the system shall require a verification code after password entry.

Where the premium plan is active,
the system shall allow up to 100 concurrent API connections.
```

### 5. Unwanted behavior（異常系）

キーワード: **If...then**

望まない状態が発生した場合の対処。

```
If the database connection is lost,
then the system shall retry up to 3 times with exponential backoff
and return a 503 status if all retries fail.

If the uploaded file exceeds the maximum size limit,
then the system shall reject the upload and display the maximum allowed size.
```

### 6. Complex（複合）

複数のキーワードを組み合わせる。

```
While the system is processing a batch job,
when a new high-priority request arrives,
the system shall queue the batch job and process the high-priority request first.

Where audit logging is enabled,
when a user modifies a protected resource,
the system shall record the actor, action, resource, and timestamp.
```

---

## EARS → GWT への導出

1つの EARS 要件から複数の GWT（受入条件）を導出する。

### 例

**REQ-001 (EARS)**:

```
When the user submits the registration form with valid data,
the system shall create the user account and send a verification email.
```

**導出される GWT**:

```
正常系:
- GIVEN 有効なデータ WHEN 登録フォーム送信 THEN アカウント作成 + 認証メール送信

異常系:
- GIVEN 重複メールアドレス WHEN 登録フォーム送信 THEN 409 エラー
- GIVEN 不正なメール形式 WHEN 登録フォーム送信 THEN バリデーションエラー
- GIVEN パスワード7文字 WHEN 登録フォーム送信 THEN バリデーションエラー

境界値:
- GIVEN パスワード8文字ちょうど WHEN 登録フォーム送信 THEN アカウント作成成功
- GIVEN ユーザー名50文字ちょうど WHEN 登録フォーム送信 THEN 成功
- GIVEN ユーザー名51文字 WHEN 登録フォーム送信 THEN バリデーションエラー
```

### 導出のチェックリスト

EARS 要件1つにつき、以下を検討する:

- [ ] 正常系: トリガー条件が満たされた場合の動作
- [ ] 異常系（入力）: 不正な入力、欠損、形式エラー
- [ ] 異常系（状態）: 前提条件が満たされない場合
- [ ] 異常系（外部）: 外部システムの障害、タイムアウト
- [ ] 境界値: 文字数、数値範囲、日時の境界
- [ ] 並行性: 同時実行、競合状態

### パターン別の導出ガイド

| EARS パターン | GWT の GIVEN に入りやすい条件 |
|-------------|---------------------------|
| Event-driven (When) | トリガーの前提状態（認証済み、未認証、権限あり/なし等） |
| State-driven (While) | 状態の開始/終了境界、状態遷移中のエッジケース |
| Optional (Where) | オプション ON/OFF、オプション間の組み合わせ |
| Unwanted (If...then) | 障害の種類・程度（部分障害、完全障害、タイムアウト） |
| Complex | 各キーワードの条件の組み合わせ |

---

## 参考

- Alistair Mavin, EARS: Easy Approach to Requirements Syntax (2009)
- https://alistairmavin.com/ears/
