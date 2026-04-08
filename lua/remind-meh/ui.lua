local M = {}

local config = require("remind-meh.config")
local scanner = require("remind-meh.scanner")

---@type UIState
M.state = {
  win = nil,
  buf = nil,
  results = {},
  filtered_results = {},
  current_filter = nil,
}

---@return WindowDimensions
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
  local ns = vim.api.nvim_create_namespace("remind_meh_ui")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  for i, item in ipairs(results) do
    local keyword_cfg = cfg.keywords[item.keyword]
    local hl_group = keyword_cfg and keyword_cfg.hl_group
        or ("RemindMeh" .. item.keyword:sub(1, 1) .. item.keyword:sub(2):lower())

    vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
      end_col = 3,
      hl_group = hl_group,
    })
    vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 3, {
      end_col = 3 + #item.keyword + 2,
      hl_group = hl_group,
    })
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
    lines = { "  No reminders found" }
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = M.state.buf })
  vim.api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = M.state.buf })

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

---Updates the floating window title to reflect current filter and result counts.
function M.update_title()
  if not M.state.win or not vim.api.nvim_win_is_valid(M.state.win) then
    return
  end

  local total = #M.state.results
  local shown = #M.state.filtered_results
  local title = " Reminders "

  if M.state.current_filter then
    title = string.format(" %s (%d/%d) ", M.state.current_filter, shown, total)
  else
    title = string.format(" Reminders (%d) ", total)
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

---Opens the reminder list floating window. If already open, closes it instead (toggle).
---Triggers an async scan if results are not provided.
---@param results? ParsedResult[]
function M.open(results)
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    M.close()
    return
  end

  local cfg = config.get()
  local dims = get_window_dimensions()

  M.state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = M.state.buf })
  vim.api.nvim_set_option_value("filetype", "remind-meh", { buf = M.state.buf })

  M.state.win = vim.api.nvim_open_win(M.state.buf, true, {
    relative = "editor",
    width = dims.width,
    height = dims.height,
    row = dims.row,
    col = dims.col,
    style = "minimal",
    border = cfg.window.border,
    title = " Reminders ",
    title_pos = "center",
  })

  vim.api.nvim_set_option_value("cursorline", true, { win = M.state.win })
  vim.api.nvim_set_option_value("winhighlight",
    "CursorLine:RemindMehCursorLine,FloatBorder:RemindMehWindowBorder", { win = M.state.win })

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

---Closes the reminder list floating window.
function M.close()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
  end
  M.state.win = nil
  M.state.buf = nil
end

---Toggles the reminder list window.
function M.toggle()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    M.close()
  else
    M.open()
  end
end

---Re-scans asynchronously and re-renders the window, preserving the active filter.
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

---Returns true if the reminder list window is currently open and valid.
---@return boolean
function M.is_open()
  return M.state.win and vim.api.nvim_win_is_valid(M.state.win)
end

return M
