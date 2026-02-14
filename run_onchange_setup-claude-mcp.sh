#!/bin/bash
# Setup Claude Code MCP servers
# Add new servers here to auto-register on all machines
if command -v claude &>/dev/null; then
  claude mcp add --scope user chrome-devtools -- npx -y chrome-devtools-mcp@latest
  claude mcp add --scope user awslabs-docs -e FASTMCP_LOG_LEVEL=ERROR -- uvx awslabs.aws-documentation-mcp-server@latest
fi