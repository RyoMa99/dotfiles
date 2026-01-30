#!/bin/bash
# lazygit の設定ディレクトリ (~/Library/Application Support/lazygit/) に
# ~/.config/lazygit/config.yml へのシンボリックリンクを作成する

set -euo pipefail

if ! command -v lazygit &>/dev/null; then
    echo "lazygit not found, skipping symlink setup" >&2
    exit 0
fi

SOURCE="$HOME/.config/lazygit/config.yml"
TARGET_DIR="$(lazygit -cd)"
TARGET="$TARGET_DIR/config.yml"

mkdir -p "$TARGET_DIR"

# 既存ファイルがシンボリックリンクでなければバックアップして置き換え
if [ -f "$TARGET" ] && [ ! -L "$TARGET" ]; then
    mv "$TARGET" "$TARGET.bak"
fi

ln -sf "$SOURCE" "$TARGET"
