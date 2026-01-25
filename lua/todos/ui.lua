local M = {}

local config = require("todos.config")
local scanner = require("todos.scanner")

M.state = {
  win = nil,
  buf = nil,
  results = {},
  filtered_results = {},
  current_filter = nil,
}

local function get_window_dimensions()
  local cfg = config.get()
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines

  local width = math.floor(editor_width * cfg.window.width)
  local height = math.floor(editor_height * cfg.window.height)

  local row = math.floor((editor_height - height) / 2)
  local col = math.floor((editor_width - width) / 2)

  return {
    width = width,
    height = height,
    row = row,
    col = col,
  }
end

local function format_line(item, cfg)
  local icon = cfg.keywords[item.keyword] and cfg.keywords[item.keyword].icon or ""
  local relative_file = vim.fn.fnamemodify(item.file, ":.")
  local text = item.text:gsub("^%s*[%-%*/]*%s*", "")
  text = text:gsub("^" .. item.keyword .. "%s*[%(%):]*%s*", "")
  text = vim.trim(text)

  if #text > 60 then
    text = text:sub(1, 57) .. "..."
  end

  return string.format(" %s %s  %s:%d  %s", icon, item.keyword, relative_file, item.line, text)
end

local function apply_line_highlights(buf, results, cfg)
  local ns = vim.api.nvim_create_namespace("todos_ui")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  for i, item in ipairs(results) do
    local hl_group = "Todos" .. item.keyword:sub(1, 1) .. item.keyword:sub(2):lower()
    vim.api.nvim_buf_add_highlight(buf, ns, hl_group, i - 1, 0, 3)
    vim.api.nvim_buf_add_highlight(buf, ns, hl_group, i - 1, 3, 3 + #item.keyword + 2)
  end
end

local function render(results)
  local cfg = config.get()

  if not M.state.buf or not vim.api.nvim_buf_is_valid(M.state.buf) then
    return
  end

  local lines = {}
  for _, item in ipairs(results) do
    table.insert(lines, format_line(item, cfg))
  end

  if #lines == 0 then
    lines = { "  No TODOs found" }
  end

  vim.api.nvim_buf_set_option(M.state.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.state.buf, "modifiable", false)

  if #results > 0 then
    apply_line_highlights(M.state.buf, results, cfg)
  end

  M.state.filtered_results = results
end

local function jump_to_item()
  if not M.state.win or not vim.api.nvim_win_is_valid(M.state.win) then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(M.state.win)
  local idx = cursor[1]
  local item = M.state.filtered_results[idx]

  if not item then
    return
  end

  M.close()

  vim.cmd("edit " .. vim.fn.fnameescape(item.file))
  vim.api.nvim_win_set_cursor(0, { item.line, item.col - 1 })
  vim.cmd("normal! zz")
end

local function filter_prompt()
  local cfg = config.get()
  local keywords = vim.tbl_keys(cfg.keywords)
  table.insert(keywords, 1, "All")

  vim.ui.select(keywords, {
    prompt = "Filter by keyword:",
  }, function(choice)
    if not choice then
      return
    end

    if choice == "All" then
      M.state.current_filter = nil
      render(M.state.results)
    else
      M.state.current_filter = choice
      local filtered = scanner.filter_by_keyword(M.state.results, choice)
      render(filtered)
    end

    M.update_title()
  end)
end

function M.update_title()
  if not M.state.win or not vim.api.nvim_win_is_valid(M.state.win) then
    return
  end

  local total = #M.state.results
  local shown = #M.state.filtered_results
  local title = " TODOs "

  if M.state.current_filter then
    title = string.format(" %s (%d/%d) ", M.state.current_filter, shown, total)
  else
    title = string.format(" TODOs (%d) ", total)
  end

  vim.api.nvim_win_set_config(M.state.win, {
    title = title,
    title_pos = "center",
  })
end

local function setup_keymaps(buf)
  local opts = { buffer = buf, noremap = true, silent = true }

  vim.keymap.set("n", "<CR>", jump_to_item, opts)
  vim.keymap.set("n", "q", M.close, opts)
  vim.keymap.set("n", "<Esc>", M.close, opts)
  vim.keymap.set("n", "f", filter_prompt, opts)
  vim.keymap.set("n", "r", function()
    M.refresh()
  end, opts)
end

function M.open(results)
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    M.close()
    return
  end

  local cfg = config.get()
  local dims = get_window_dimensions()

  M.state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(M.state.buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(M.state.buf, "filetype", "todos")

  M.state.win = vim.api.nvim_open_win(M.state.buf, true, {
    relative = "editor",
    width = dims.width,
    height = dims.height,
    row = dims.row,
    col = dims.col,
    style = "minimal",
    border = cfg.window.border,
    title = " TODOs ",
    title_pos = "center",
  })

  vim.api.nvim_win_set_option(M.state.win, "cursorline", true)
  vim.api.nvim_win_set_option(M.state.win, "winhighlight", "CursorLine:TodosCursorLine,FloatBorder:TodosWindowBorder")

  setup_keymaps(M.state.buf)

  if results then
    M.state.results = results
    M.state.current_filter = nil
    render(results)
    M.update_title()
  else
    scanner.scan_async(function(scan_results)
      M.state.results = scan_results
      M.state.current_filter = nil
      render(scan_results)
      M.update_title()
    end)
  end
end

function M.close()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
  end
  M.state.win = nil
  M.state.buf = nil
end

function M.toggle()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    M.close()
  else
    M.open()
  end
end

function M.refresh()
  scanner.scan_async(function(results)
    M.state.results = results
    if M.state.current_filter then
      local filtered = scanner.filter_by_keyword(results, M.state.current_filter)
      render(filtered)
    else
      render(results)
    end
    M.update_title()
  end)
end

function M.is_open()
  return M.state.win and vim.api.nvim_win_is_valid(M.state.win)
end

return M
