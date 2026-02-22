# Naming Review Reference

レビュー時の詳細な判断基準と出力例。

## 段階判定の詳細

### Stage 1: Missing

名前のない概念がコード内に埋もれている。

**検出方法**:
- 長いメソッド内のひとまとまりの処理
- 複雑な式や計算
- よく一緒に渡されるパラメータ群

**例**:
```typescript
// 検証ロジックが埋もれている
function processOrder(order) {
  if (order.items.length === 0 || order.total < 0) {
    throw new Error('Invalid order');
  }
  // ... 処理続く
}
```

### Stage 2: Nonsense

意味のない汎用的な名前。

**典型例**: `data`, `info`, `temp`, `result`, `item`, `value`, `obj`

```typescript
// BAD
function processData(data) { ... }

// 一時的なマーカーとしてのNonsense（意図的）
function applesauce(order) { /* TODO: 適切な名前に */ }
```

### Stage 3: Honest

主要な作用は反映しているが、副作用が隠れている。

```typescript
// 名前は insert だが、通知も送っている
function insertUser(user) {
  db.insert(user);
  mailer.sendWelcome(user.email);  // 隠れた副作用
}
```

### Stage 4: Honest and Complete

全ての作用を名前に含めている。名前が長くなる。

```typescript
function insertUserAndSendWelcomeEmailAndTrackAnalytics(user) { ... }
```

**これは問題のサイン** → Stage 5 で分割が必要。

### Stage 5: Does the Right Thing

単一責務に分割されている。

```typescript
function insertUser(user) { db.insert(user); }
function sendWelcomeEmail(email) { mailer.send(email); }
function trackUserCreation(userId) { analytics.track('user_created', userId); }
```

### Stage 6: Intent

「何をするか」ではなく「なぜ必要か」を表現。

```typescript
// Stage 5: 何をするか
function storeFlightToDatabase() {}
function startFlightProcessing() {}

// Stage 6: なぜ必要か
function beginTrackingFlight() {}
```

### Stage 7: Domain Abstraction

ドメイン概念として統一されている。

```typescript
// Before: プリミティブ
function calculateDistance(x1, y1, x2, y2) {}

// After: ドメイン抽象
function calculateDistance(from: Location, to: Location): Distance {}
```

---

## 問題パターン詳細

### プリミティブ型への執着

**兆候**:
- 同じパラメータの組み合わせが繰り返し使われる
- 型名と同じ変数名（`user: User`）
- 単位や制約が名前に含まれる（`rangeInMeters: number`）

**改善**: Value Object の導入

### 曖昧なサフィックス

**問題のある命名**:
- `UserManager` - 何を管理？
- `DataHandler` - 何をハンドル？
- `OrderProcessor` - どう処理？

**改善**: 具体的な責務を名前に

### Feature Envy

**兆候**: 他オブジェクトのデータに頻繁にアクセス

```typescript
// BAD: Order の中身を触りすぎ
function calculateOrderDiscount(order) {
  const subtotal = order.items.reduce((sum, i) => sum + i.price, 0);
  if (order.customer.isVip) { ... }
}

// GOOD: Order に責務を移動
order.calculateDiscount();
```

---

## 出力フォーマット例

```markdown
# 命名レビュー: src/services/UserService.ts

## サマリー

| 項目 | 値 |
|------|-----|
| 評価した識別子 | 12 |
| 問題検出 | 4 |
| 優先度高 | 2 |

### 段階別分布
- Stage 3 (Honest): 2
- Stage 5 (Does the Right Thing): 8
- Stage 6 (Intent): 2

## 詳細な改善提案

### 1. `createUser` (UserService.ts:45)

**現在の段階**: Stage 3 (Honest)
**問題**: 副作用（メール送信、analytics）が名前に反映されていない

**現在のコード**:
```typescript
async createUser(userData: UserInput): Promise<User> {
  const user = await this.repository.insert(userData);
  await this.mailer.sendWelcome(user.email);
  this.analytics.track('user_created', user.id);
  return user;
}
```

**改善案**:

Option A: 名前を完全にする（Stage 4）
```typescript
async createUserAndNotify(userData: UserInput): Promise<User>
```

Option B: 責務を分割する（Stage 5）- **推奨**
```typescript
async createUser(userData: UserInput): Promise<User> {
  return this.repository.insert(userData);
}

async onUserCreated(user: User): Promise<void> {
  await this.mailer.sendWelcome(user.email);
  this.analytics.track('user_created', user.id);
}
```

**推奨理由**: 単一責務の原則に従い、テスタビリティが向上

---

### 2. `data` (UserService.ts:78)

**現在の段階**: Stage 2 (Nonsense)
**問題**: 汎用的すぎる変数名

**現在のコード**:
```typescript
const data = await this.fetchUserProfile(userId);
```

**改善案**:
```typescript
const userProfile = await this.fetchUserProfile(userId);
```

---

## ドメイン抽象化の候補

| パラメータ群 | 推奨 Value Object |
|-------------|------------------|
| (lat, lng) | `Location` |
| (startDate, endDate) | `DateRange` |

## 次のアクション

1. [ ] `createUser` の責務分割
2. [ ] 汎用変数名 `data` の改善
3. [ ] `Location` Value Object の導入を検討
```
