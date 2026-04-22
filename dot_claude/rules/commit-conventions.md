---
alwaysApply: true
---

# コミット規約

- コミットメッセージは日本語で書く
- 末尾に `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>` を付ける
- コミットメッセージは `git commit -F -` で stdin から渡す（サブシェル `$(...)` は heredoc のネストでパース不具合を起こすため避ける）

```bash
# GOOD: -F - で stdin から渡す
git commit -F - <<'EOF'
feat: 機能追加

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
```

```bash
# BAD: サブシェル $(cat <<'EOF' ...) を使わない
git commit -m "$(cat <<'EOF'
feat: 機能追加

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```
