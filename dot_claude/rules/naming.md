---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# 命名の原則

kawasima氏の「命名のプロセス」に基づく命名の進化的アプローチ。

関連: @~/.claude/rules/robust-code.md（型による予防的設計、Value Object）

---

## 核心思想

> 良い命名は単一ステップではなく**プロセス**である。
> 最初から完璧を目指すのではなく、段階的に改善していく。

命名は設計であり、コードの読みやすさに直結する。

---

## 7段階の命名進化

命名の質を段階的に向上させるプロセス：

| 段階 | 名前 | 状態 |
|------|------|------|
| 1 | Missing | 抽象化すべき概念に名前がない |
| 2 | Nonsense | 意図的に無意味な名前（Applesauce等） |
| 3 | Honest | 主要な作用を反映した名前 |
| 4 | Honest and Complete | 全ての作用を表現 |
| 5 | Does the Right Thing | 単一責務に分割された状態 |
| 6 | Intent | なぜ必要かを示す名前 |
| 7 | Domain Abstraction | 統一されたドメイン概念 |

---

## Stage 1-2: Missing → Nonsense

### 名前がない概念を見つける

**長いものに注目**：
- 長いメソッド、クラス、ファイル
- 長い引数リスト
- 複雑な式

**塊を探す**：
- ひとまとまりの文
- 明確でない式（計算や論理）
- よく一緒に渡されるパラメータ

### Nonsense名で抽出

意図的に無意味な名前を付けて「未完成」を明示：

```typescript
// BAD: 誤解を招く名前のまま放置
function processData(data) { /* 実際は検証もしている */ }

// GOOD: 一時的にナンセンス名で抽出
function applesauce(data) { /* 後で適切な名前に */ }
```

リファクタリング手法：
- **メソッド抽出** - 文の塊に名前を付ける
- **変数導入** - 式に名前を付ける
- **パラメータオブジェクト導入** - パラメータ集合に名前を付ける

---

## Stage 3: Nonsense → Honest

メソッドの中心となる1つの概念を理解し、実直な名前にする。

### コード内のパターンを探す

- システムコンポーネント変数（database、screen、network）
- 繰り返されるパターン
- 戻り値の使われ方

### 命名のコツ

```typescript
// 分からないことを明確にする
function probably_doSomethingToDatabase_AndStuff() {}

// ↓ 理解が進んだら更新
function probably_insertUser_AndValidate() {}
```

**重要**: **何であるか**ではなく**何をするか**で命名する

---

## Stage 4: Honest → Honest and Complete

メソッドがしている**すべて**を名前で表現する。

### 分かっていることを広げる

```typescript
// Before: 一部だけ
function insertUser() {}

// After: 全ての作用を含める
function insertUserAndSendWelcomeEmail() {}
```

### 長い名前は問題のサイン

名前が長くなるのは**設計の問題を示すシグナル**。
次のステージで責務を分割する。

---

## Stage 5: Does the Right Thing

責務を分割し、単一責務の原則に従う。

### 分割の手順

1. 名前から排除したい部分を特定
2. その部分が他と無関係か確認
3. 構造的リファクタリングを実施

```typescript
// Before: 複数責務
function insertUserAndSendWelcomeEmail(user) {
  db.insert(user);
  mailer.send(user.email, 'Welcome!');
}

// After: 単一責務に分割
function insertUser(user) {
  db.insert(user);
}

function sendWelcomeEmail(email) {
  mailer.send(email, 'Welcome!');
}
```

---

## Stage 6: Intent（意図）

**何をしているか**から**なぜ必要か**へ転換する。

### 見るべき対象

- **メソッド**: 事後条件、実現される変換、ビジネスプロセス
- **クラス**: 共通責務、現実世界の対応物
- **変数**: 同じ型の他インスタンスとの違い

### 例

```typescript
// Honest and Complete（何をするか）
function storeFlightToDatabaseAndStartProcessing() {}

// Intent（なぜ必要か）
function beginTrackingFlight() {}
```

### 避けるべきパターン

- 初期条件で命名（いつ使われるか）
- コンピュータ科学用語のみ使用
- ドメイン文脈を欠いた命名

---

## Stage 7: Domain Abstraction

共有コンテキストと統一されたドメイン概念を形成する。

### 探すべきパターン

**クラス群**:
- 類似の名前（Thing/ThingIsValid）
- Manager、Transform、～er で終わる名前
- Feature Envy（他オブジェクトにアクセスしすぎ）

**メソッド群**:
- 一緒に渡される複数パラメータ
- 同じデータへの操作
- 類似の名前（begin/end、create/read/update/destroy）

**フィールド/パラメータ**:
- 型名と同じ変数名
- 許容値や解釈が必要な名前（`rangeInMeters: int`）

### Value Object の導入

```typescript
// Before: プリミティブ型
function calculateDistance(startX: number, startY: number, endX: number, endY: number) {}

// After: ドメイン抽象
function calculateDistance(start: Point, end: Point): Distance {}
```

---

## チェックリスト

コードレビュー時に確認：

- [ ] 名前のない概念が放置されていないか
- [ ] 誤解を招く名前はないか
- [ ] メソッド名は主要な作用を反映しているか
- [ ] 名前が長すぎる（責務が多すぎる）サインはないか
- [ ] 何をするかではなく、なぜ必要かを表現しているか
- [ ] ドメイン用語を適切に使用しているか
- [ ] プリミティブ型への執着はないか（Value Object化の検討）

---

## 技術的負債への視点

> プログラマはプログラミング全体の60-70%をコードを読むことに費やしている

したがって：
- 技術的負債 = 読みやすさの欠如
- バグは不完全な理解から発生
- 読みやすいコードが最高の投資

---

## 参考資料

- [kawasima - 命名のプロセス](https://scrapbox.io/kawasima/%E5%91%BD%E5%90%8D%E3%81%AE%E3%83%97%E3%83%AD%E3%82%BB%E3%82%B9)
