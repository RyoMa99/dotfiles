#!/bin/bash
# Install ollama models listed in ~/.config/ollama/models.txt
if command -v ollama &>/dev/null; then
  while IFS= read -r model; do
    [ -n "$model" ] && ollama pull "$model"
  done < "$HOME/.config/ollama/models.txt"
fi
