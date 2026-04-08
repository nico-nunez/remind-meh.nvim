local M = {}

local config = require("remind-meh.config")
local highlights = require("remind-meh.highlights")
local scanner = require("remind-meh.scanner")
local ui = require("remind-meh.ui")

M._initialized = false

local function get_username()
  local cfg = config.get()
  if cfg.user then
    return cfg.user
  end

  local handle = io.popen("git config user.name 2>/dev/null")
  if handle then
    local result = handle:read("*a"):gsub("%s+$", "")
    handle:close()
    if result ~= "" then
      return result
    end
  end

  return vim.env.USER or "user"
end

local function build_keyword_pattern()
  local cfg = config.get()
  local keywords = vim.tbl_keys(cfg.keywords)
  return [[\v(]] .. table.concat(keywords, "|") .. [[)\s*(\(.*\))?\s*:]]
end

---Jumps to the next TODO keyword in the current buffer, wrapping at end of file.
function M.next_todo()
  local pattern = build_keyword_pattern()
  local saved_view = vim.fn.winsaveview()

  -- Move cursor right one column to avoid matching current position
  vim.cmd("normal! l")

  local found = vim.fn.search(pattern, "W")
  if found == 0 then
    -- Wrap to beginning of file
    vim.fn.cursor(1, 1)
    found = vim.fn.search(pattern, "W")
    if found == 0 then
      vim.fn.winrestview(saved_view)
      vim.notify("No TODOs found in buffer", vim.log.levels.INFO)
      return
    end
    vim.notify("Wrapped to beginning of file", vim.log.levels.INFO)
  end
  vim.cmd("normal! zz")
end

---Jumps to the previous TODO keyword in the current buffer, wrapping at beginning of file.
function M.prev_todo()
  local pattern = build_keyword_pattern()
  local saved_view = vim.fn.winsaveview()

  -- Move cursor left one column to avoid matching current position
  vim.cmd("normal! h")

  local found = vim.fn.search(pattern, "bW")
  if found == 0 then
    -- Wrap to end of file
    vim.fn.cursor(vim.fn.line("$"), vim.fn.col("$"))
    found = vim.fn.search(pattern, "bW")
    if found == 0 then
      vim.fn.winrestview(saved_view)
      vim.notify("No TODOs found in buffer", vim.log.levels.INFO)
      return
    end
    vim.notify("Wrapped to end of file", vim.log.levels.INFO)
  end
  vim.cmd("normal! zz")
end

---Inserts a TODO comment at the current cursor position and enters insert mode.
---Uses the buffer's commentstring. Inserts on the current line if empty, otherwise above it.
function M.insert_todo()
  local comment = vim.bo.commentstring
  if comment == "" or comment == nil then
    comment = "// %s"
  end
  local prefix = comment:gsub("%%s", ""):gsub("%s*$", "")
  if prefix ~= "" then
    prefix = prefix .. " "
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local current_line = vim.api.nvim_get_current_line()

  -- 1. Extract indentation and build prefix
  local indentation = current_line:match("^%s*")
  local user = get_username()
  local text = string.format("%sTODO(%s): ", prefix, user)
  local formatted_text = indentation .. text

  -- 2. Decide where to put it (current line if empty, otherwise above)
  if current_line:match("%S") then
    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { formatted_text })
  else
    vim.api.nvim_set_current_line(formatted_text)
  end

  vim.api.nvim_win_set_cursor(0, { row, #formatted_text })
  vim.cmd("startinsert!")
end

---Opens the multi-line TODO input floating window.
function M.input_todo()
  local input = require("remind-meh.input")
  input.open()
end

---Returns the username used for TODO attribution (git config user.name, $USER, or "user").
---@return string
function M.get_username()
  return get_username()
end

---Sets up the plugin, registers keymaps, and initializes highlights.
---No-op if called more than once.
---@param opts? RemindMehConfig
function M.setup(opts)
  if M._initialized then
    return
  end

  config.setup(opts)
  highlights.setup()
  highlights.setup_buffer_autocmd()

  local cfg = config.get()

  if cfg.keymap then
    vim.keymap.set("n", cfg.keymap, function()
      M.toggle()
    end, { desc = "Toggle reminder list", silent = true })
  end

  if cfg.insert_keymap then
    vim.keymap.set("n", cfg.insert_keymap, function()
      M.insert_todo()
    end, { desc = "Insert TODO at cursor", silent = true })
  end

  if cfg.input_keymap then
    vim.keymap.set("n", cfg.input_keymap, function()
      M.input_todo()
    end, { desc = "Open TODO input window", silent = true })
  end

  if cfg.next_keymap then
    vim.keymap.set("n", cfg.next_keymap, function()
      M.next_todo()
    end, { desc = "Jump to next TODO", silent = true })
  end

  if cfg.prev_keymap then
    vim.keymap.set("n", cfg.prev_keymap, function()
      M.prev_todo()
    end, { desc = "Jump to previous TODO", silent = true })
  end

  M._initialized = true
end

---Toggles the reminder list window open or closed.
function M.toggle()
  ui.toggle()
end

---Opens the reminder list window. Triggers an async scan if no results are passed.
---@param results? ParsedResult[]
function M.open(results)
  ui.open(results)
end

---Closes the reminder list window.
function M.close()
  ui.close()
end

---Re-scans and refreshes the reminder list window contents.
function M.refresh()
  ui.refresh()
end

---Synchronously scans for TODO keywords and returns the results.
---@param opts? ScanOpts
---@return ParsedResult[]
function M.scan(opts)
  return scanner.scan(opts)
end

---Asynchronously scans for TODO keywords and calls callback with results.
---@param callback fun(results: ParsedResult[])
---@param opts? ScanOpts
function M.scan_async(callback, opts)
  scanner.scan_async(callback, opts)
end

---Returns the cached results from the last scan.
---@return ParsedResult[]
function M.get_todos()
  return scanner.get_cached()
end

---Returns a compact statusline string with TODO/FIXME/BUG counts and icons.
---@return string
function M.statusline()
  local statusline = require("remind-meh.statusline")
  return statusline.get_status()
end

---Returns whether the reminder list window is currently open.
---@return boolean
function M.is_open()
  return ui.is_open()
end

---Runs an async scan on startup and opens the window if any results are found.
---Respects the `auto_open` config option.
function M.auto_open()
  local cfg = config.get()
  if not cfg.auto_open then
    return
  end

  scanner.scan_async(function(results)
    if #results > 0 then
      vim.schedule(function()
        ui.open(results)
      end)
    end
  end)
end

return M
