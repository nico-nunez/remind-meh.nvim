local M = {}

local config = require("todos.config")

local theme_map = {
  TODO = { hl = "@comment.todo", fallback = "#FFFF00" },
  FIXME = { hl = "DiagnosticError", fallback = "#FF6B6B" },
  BUG = { hl = "DiagnosticError", fallback = "#F7768E" },
  HACK = { hl = "DiagnosticWarn", fallback = "#FF9E64" },
  NOTE = { hl = "DiagnosticInfo", fallback = "#7DCFFF" },
  XXX = { hl = "DiagnosticHint", fallback = "#BB9AF7" },
}

local function get_theme_color(hl_group, fallback)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = hl_group, link = false })
  if ok and hl and hl.fg then
    return string.format("#%06x", hl.fg)
  end
  return fallback
end

local function resolve_color(keyword, settings, use_theme)
  if use_theme and theme_map[keyword] then
    return get_theme_color(theme_map[keyword].hl, theme_map[keyword].fallback)
  end
  return settings.color
end

function M.setup()
  local opts = config.get()
  local use_theme = opts.theme == "auto"

  for keyword, settings in pairs(opts.keywords) do
    local color = resolve_color(keyword, settings, use_theme)
    local hl_group = "Todos" .. keyword:sub(1, 1) .. keyword:sub(2):lower()
    vim.api.nvim_set_hl(0, hl_group, {
      fg = color,
      bold = true,
    })

    -- TODO: Implement background highlight style option (highlight_style = "bg")
    -- local bg_group = hl_group .. "Bg"
    -- vim.api.nvim_set_hl(0, bg_group, {
    --   fg = color,
    --   bg = color,
    --   blend = 80,
    --   bold = true,
    -- })
  end

  vim.api.nvim_set_hl(0, "TodosWindowTitle", {
    fg = "#7DCFFF",
    bold = true,
  })

  vim.api.nvim_set_hl(0, "TodosWindowBorder", {
    fg = "#565f89",
  })

  vim.api.nvim_set_hl(0, "TodosCursorLine", {
    bg = "#2a2e3f",
  })

  vim.api.nvim_set_hl(0, "TodosFile", {
    fg = "#9ece6a",
  })

  vim.api.nvim_set_hl(0, "TodosLineNr", {
    fg = "#565f89",
  })
end

function M.apply_to_buffer(bufnr)
  local opts = config.get()

  for keyword, _ in pairs(opts.keywords) do
    local hl_group = "Todos" .. keyword:sub(1, 1) .. keyword:sub(2):lower()
    local pattern = [[\v]] .. keyword .. [[(\(.*\))?:?]]
    vim.fn.matchadd(hl_group, pattern, 10, -1, { window = vim.api.nvim_get_current_win() })
  end
end

function M.setup_buffer_autocmd()
  local group = vim.api.nvim_create_augroup("TodosHighlight", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = group,
    callback = function(ev)
      local ft = vim.bo[ev.buf].filetype
      local excluded = { "TelescopePrompt", "NvimTree", "neo-tree", "lazy", "mason", "help" }
      if not vim.tbl_contains(excluded, ft) then
        M.apply_to_buffer(ev.buf)
      end
    end,
  })
end

return M
