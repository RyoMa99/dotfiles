# mise

mise（旧 rtx）によるツールバージョン管理の知見。

---

## 設定ファイル

- `mise use <tool>@<version>` はデフォルトで `mise.toml` を生成する（`.tool-versions` ではない）
- `.tool-versions` を生成したい場合は `mise settings set idiomatic_version_file_enable_tools []` 等の設定が必要
- `mise.toml` は mise のネイティブ形式で、`.tool-versions` と機能的に等価
