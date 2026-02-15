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
