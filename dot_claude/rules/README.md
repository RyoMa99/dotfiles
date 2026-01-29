# ナレッジベース（rules/）

プロジェクト横断で活用できる学習内容を蓄積するディレクトリ。

## ファイル構成

各ファイルは特定の技術領域ごとに整理：

```
rules/
├── README.md          # このファイル
├── robust-code.md     # 堅牢なコードの設計原則（t_wada）
├── testing.md         # テストの原則（t_wada）
├── security.md        # セキュリティルール
├── troubleshooting.md # 問題解決のパターン
├── type-granularity.md # 型の粒度設計（kawasima）
└── domain-modeling.md  # ドメインモデリング（kawasima）
```

## 記載ルール

1. **プロジェクト固有の情報は除外**（秘密情報、リソース名など）
2. **再利用可能な形で記載**
3. **コード例を含める**
4. **既存の内容と重複しない**

## 更新方法

`/sync-knowledge` スキルを使用して、プロジェクトの学習内容を自動で追記。

```
/sync-knowledge
```
