local function get_git_root()
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 or not git_root then
    return nil
  end
  return git_root
end

return {
  dir = ".",
  name = "arto",
  keys = {
    {
      "<Leader>md",
      function()
        local git_root = get_git_root()
        if not git_root then
          vim.notify("Git repository not found", vim.log.levels.ERROR)
          return
        end

        local file_path = vim.fn.expand("%:p")
        vim.fn.jobstart({ "arto", "--directory=" .. git_root, file_path }, { detach = true })

        vim.defer_fn(function()
          vim.fn.jobstart({
            "osascript",
            "-e",
            'tell application "System Events" to tell process "arto" to set position of front window to {0, 25}',
            "-e",
            'tell application "System Events" to tell process "arto" to set size of front window to {9999, 9999}',
          })
        end, 500)
      end,
      desc = "Arto で現在のファイルを開く",
    },
  },
}
