#!/bin/bash
# Setup Claude Code MCP servers
# Add new servers here to auto-register on all machines
# chezmoi apply 時に Claude Code セッション内でも動作する

unset CLAUDECODE

if ! command -v claude &>/dev/null; then
  exit 0
fi

registered=$(claude mcp list 2>/dev/null)

add_mcp() {
  local name="$1"
  shift
  if echo "$registered" | grep -q "^${name}:"; then
    echo "skip: ${name} (already registered)"
    return
  fi
  echo "add: ${name}"
  claude "$@"
}

add_mcp chrome-devtools mcp add --scope user chrome-devtools -- npx -y chrome-devtools-mcp@latest
add_mcp awslabs-docs mcp add --scope user awslabs-docs -e FASTMCP_LOG_LEVEL=ERROR -- uvx awslabs.aws-documentation-mcp-server@latest