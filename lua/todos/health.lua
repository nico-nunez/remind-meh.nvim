local M = {}

M.check = function()
  vim.health.start("todos.nvim")

  -- Check Neovim version
  local nvim_version = vim.version()
  if nvim_version.major > 0 or (nvim_version.major == 0 and nvim_version.minor >= 9) then
    vim.health.ok(string.format("Neovim version %d.%d.%d (>= 0.9 required)", nvim_version.major, nvim_version.minor, nvim_version.patch))
  else
    vim.health.error(
      string.format("Neovim version %d.%d.%d is too old", nvim_version.major, nvim_version.minor, nvim_version.patch),
      "Update to Neovim 0.9 or later"
    )
  end

  -- Check for ripgrep
  if vim.fn.executable("rg") == 1 then
    local handle = io.popen("rg --version 2>/dev/null")
    local version = ""
    if handle then
      version = handle:read("*l") or ""
      handle:close()
    end
    vim.health.ok("ripgrep installed: " .. version)
  else
    vim.health.warn(
      "ripgrep not found",
      {
        "Install ripgrep for faster scanning and .gitignore support",
        "  macOS: brew install ripgrep",
        "  Ubuntu: apt install ripgrep",
        "  Arch: pacman -S ripgrep",
        "  https://github.com/BurntSushi/ripgrep#installation",
        "The plugin will fall back to grep (slower, no .gitignore support)",
      }
    )
  end

  -- Check grep fallback
  if vim.fn.executable("grep") == 1 then
    vim.health.ok("grep available as fallback")
  else
    if vim.fn.executable("rg") ~= 1 then
      vim.health.error("Neither ripgrep nor grep found", "Install ripgrep or grep for TODO scanning")
    end
  end

  -- Check plugin initialization
  local todos = require("todos")
  if todos._initialized then
    vim.health.ok("Plugin initialized")
  else
    vim.health.warn(
      "Plugin not initialized",
      'Call require("todos").setup() in your config'
    )
  end

  -- Check configuration
  local config = require("todos.config")
  local opts = config.get()

  if opts.keywords and next(opts.keywords) then
    local keyword_count = vim.tbl_count(opts.keywords)
    vim.health.ok(string.format("Configuration loaded (%d keywords)", keyword_count))
  else
    vim.health.error("No keywords configured", "Check your setup() call")
  end

  -- Check theme setting
  if opts.theme == "auto" then
    vim.health.info("Theme mode: auto (adapts to colorscheme)")
  else
    vim.health.info("Theme mode: custom (using configured colors)")
  end
end

return M
