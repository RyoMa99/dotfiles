#!/bin/bash
# Setup global agent skills via npx skills
# chezmoi apply 時に自動インストール
# hash: 6a8b3c (スキル定義を変更したらハッシュを更新して再実行させる)

if ! command -v npx &>/dev/null; then
  echo "npx not found, skipping agent skills setup"
  exit 0
fi

add_skills() {
  local repo="$1"
  shift
  local needs_install=false
  local skill_args=""

  for skill in "$@"; do
    if [ ! -d "$HOME/.agents/skills/$skill" ]; then
      needs_install=true
      skill_args="$skill_args --skill $skill"
    else
      echo "skip: $skill (already installed)"
    fi
  done

  if [ "$needs_install" = true ]; then
    echo "install: $repo ($skill_args)"
    npx -y skills add "$repo" --global $skill_args --yes
  fi
}

add_skills yoshiko-pg/difit difit difit-review
