-- ディレクトリパスからポート番号を生成（3000-3999の範囲）
local function get_port(path)
  local sum = 0
  for i = 1, #path do
    sum = sum + string.byte(path, i)
  end
  return 3000 + (sum % 1000)
end

local function get_git_root()
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 or not git_root then
    return nil
  end
  return git_root
end

local function heading_to_slug(text)
  return text:lower():gsub("%s+", "-")
end

local function generate_sidebar(git_root)
  local skip_dirs = { "node_modules", ".git", "docs/plan" }
  local skip_files = { "_sidebar.md", "CLAUDE.md" }
  local files = vim.fn.glob(git_root .. "/**/*.md", false, true)
  -- git root直下の.mdも含める
  for _, f in ipairs(vim.fn.glob(git_root .. "/*.md", false, true)) do
    if not vim.tbl_contains(files, f) then
      table.insert(files, 1, f)
    end
  end

  local lines = {}
  for _, filepath in ipairs(files) do
    local relative = filepath:sub(#git_root + 2)
    -- 除外パターン
    local skip = false
    for _, name in ipairs(skip_files) do
      if relative == name then
        skip = true
        break
      end
    end
    if not skip then
      for _, dir in ipairs(skip_dirs) do
        if relative:find("^" .. dir:gsub("%-", "%%-") .. "/") then
          skip = true
          break
        end
      end
    end
    if skip then
      goto continue
    end

    local ok, content = pcall(vim.fn.readfile, filepath)
    if not ok then
      goto continue
    end

    local file_title = relative:match("([^/]+)%.md$") or relative
    local has_h1 = false
    local in_fence = false
    for _, line in ipairs(content) do
      if line:match("^```") then
        in_fence = not in_fence
      elseif not in_fence and line:match("^# ") then
        has_h1 = true
        break
      end
    end

    if not has_h1 then
      table.insert(lines, ("- [%s](%s)"):format(file_title, relative))
    end

    local in_code_block = false
    for _, line in ipairs(content) do
      if line:match("^```") then
        in_code_block = not in_code_block
      elseif not in_code_block then
        local level, title = line:match("^(#+)%s+(.+)$")
        if level and title then
          local depth = #level
          if depth == 1 then
            table.insert(lines, ("- [%s](%s)"):format(title, relative))
          elseif depth <= 3 then
            local indent = string.rep("  ", depth - 1)
            local slug = heading_to_slug(title)
            table.insert(lines, ("%s- [%s](%s?id=%s)"):format(indent, title, relative, slug))
          end
        end
      end
    end

    ::continue::
  end

  local sidebar_path = git_root .. "/_sidebar.md"
  vim.fn.writefile(lines, sidebar_path)
end

return {
  dir = ".",
  name = "docsify",
  keys = {
    {
      "<Leader>md",
      function()
        local git_root = get_git_root()
        if not git_root then
          vim.notify("Git repository not found", vim.log.levels.ERROR)
          return
        end
        local nvim_dir = vim.fn.expand("~/.config/nvim")
        local docsify_bin = nvim_dir .. "/node_modules/.bin/docsify"
        local index_html = git_root .. "/docsify.html"

        -- docsify.htmlを作成（存在しない場合のみ）
        if vim.fn.filereadable(index_html) == 0 then
          local html = [[<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/docsify/themes/vue.css">
  <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
  <script>mermaid.initialize({ startOnLoad: false });</script>
</head>
<body>
  <div id="app"></div>
  <script>
    window.$docsify = {
      loadSidebar: true,
      auto2top: true,
      markdown: {
        renderer: {
          code: function(code, lang) {
            if (lang === 'mermaid') {
              return '<div class="mermaid">' + code + '</div>';
            }
            return this.origin.code.apply(this, arguments);
          }
        }
      },
      plugins: [
        function(hook) {
          hook.doneEach(function() {
            setTimeout(function() {
              mermaid.run({ querySelector: '.mermaid' });
            }, 100);
          });
        }
      ]
    }
  </script>
  <script src="https://cdn.jsdelivr.net/npm/docsify/lib/docsify.min.js"></script>
</body>
</html>]]
          vim.fn.writefile(vim.split(html, "\n"), index_html)
        end

        generate_sidebar(git_root)

        local port = get_port(git_root)
        local file_path = vim.fn.expand("%:p")
        local relative = file_path:sub(#git_root + 2)
        local url = "http://localhost:" .. port .. "/#/" .. relative
        vim.fn.jobstart({ docsify_bin, "serve", git_root, "--port", tostring(port), "--index-name", "docsify.html" })
        vim.defer_fn(function()
          vim.fn.jobstart({ "open", url }, { detach = true })
        end, 1000)
        vim.notify("Docsify started on port " .. port, vim.log.levels.INFO)
      end,
      desc = "Docsify サーバー起動",
    },
    {
      "<Leader>mo",
      function()
        local git_root = get_git_root()
        if not git_root then
          vim.notify("Git repository not found", vim.log.levels.ERROR)
          return
        end

        local file_path = vim.fn.expand("%:p")
        local relative = file_path:sub(#git_root + 2)
        local port = get_port(git_root)

        vim.fn.jobstart({ "open", "http://localhost:" .. port .. "/#/" .. relative }, { detach = true })
      end,
      desc = "現在のファイルをdocsifyで開く",
    },
  },
}
