local M = {}

local config = require("remind-meh.config")

-- Namespace for extmarks (RemindMeh::extmarks, if you will)
local ns = vim.api.nvim_create_namespace("RemindMeh")

local theme_map = {
  TODO = { hl = "@comment.todo", fallback = "#FFFF00" },
  FIXME = { hl = "DiagnosticError", fallback = "#FF6B6B" },
  BUG = { hl = "DiagnosticError", fallback = "#F7768E" },
  HACK = { hl = "DiagnosticWarn", fallback = "#FF9E64" },
  NOTE = { hl = "DiagnosticInfo", fallback = "#7DCFFF" },
  WARNING = { hl = "DiagnosticWarn", fallback = "#FF9E64" },
  IMPORTANT = { hl = "DiagnosticError", fallback = "#FF6B6B" },
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

---Registers all RemindMeh highlight groups based on current config and theme setting.
function M.setup()
  local opts = config.get()
  local use_theme = opts.theme == "auto"

  for keyword, settings in pairs(opts.keywords) do
    local color = resolve_color(keyword, settings, use_theme)
    local hl_group = "RemindMeh" .. keyword:sub(1, 1) .. keyword:sub(2):lower()
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

  vim.api.nvim_set_hl(0, "RemindMehWindowTitle", {
    fg = "#7DCFFF",
    bold = true,
  })

  vim.api.nvim_set_hl(0, "RemindMehWindowBorder", {
    fg = "#565f89",
  })

  vim.api.nvim_set_hl(0, "RemindMehCursorLine", {
    bg = "#2a2e3f",
  })

  vim.api.nvim_set_hl(0, "RemindMehFile", {
    fg = "#9ece6a",
  })

  vim.api.nvim_set_hl(0, "RemindMehLineNr", {
    fg = "#565f89",
  })
end

---Applies keyword highlight extmarks to all comment nodes in the given buffer.
---Uses tree-sitter to find comment ranges; no-op if no parser is available.
---@param bufnr integer
function M.apply_to_buffer(bufnr)
  -- Clear existing extmarks for this buffer
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local opts = config.get()

  -- Try to get treesitter parser for this buffer
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return
  end

  -- Try to parse the query for comments
  local query_ok, query = pcall(vim.treesitter.query.parse, parser:lang(), "(comment) @comment")
  if not query_ok or not query then
    return
  end

  local tree = parser:parse()[1]
  if not tree then
    return
  end

  -- Iterate through all comment nodes
  for _, node in query:iter_captures(tree:root(), bufnr) do
    local start_row, start_col, end_row, end_col = node:range()

    -- Get the lines this comment spans
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)

    for i, line in ipairs(lines) do
      local row = start_row + i - 1
      local line_start_col = (i == 1) and start_col or 0
      local line_end_col = (i == #lines) and end_col or #line

      -- Only search within the comment portion of this line
      local comment_text = line:sub(line_start_col + 1, line_end_col)

      -- Check each keyword
      for keyword, _ in pairs(opts.keywords) do
        local search_start = 1
        while true do
          local match_start, match_end = comment_text:find(keyword, search_start, true)
          if not match_start then
            break
          end

          local hl_group = "RemindMeh" .. keyword:sub(1, 1) .. keyword:sub(2):lower()
          local col = line_start_col + match_start - 1

          vim.api.nvim_buf_set_extmark(bufnr, ns, row, col, {
            end_row = row,
            end_col = col + #keyword,
            hl_group = hl_group,
          })

          search_start = match_end + 1
        end
      end
    end
  end
end

---Registers autocmds to re-apply highlights on BufEnter, InsertLeave, and BufWritePost.
function M.setup_buffer_autocmd()
  local group = vim.api.nvim_create_augroup("RemindMehHighlight", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "BufWritePost" }, {
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
