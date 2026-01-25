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

function M.insert_todo()
  local comment = vim.bo.commentstring
  if comment == "" or comment == nil then
    comment = "// %s"
  end
  local prefix = comment:gsub("%%s", ""):gsub("%s*$", "")
  if prefix ~= "" then
    prefix = prefix .. " "
  end

  local user = get_username()
  local text = string.format("%sTODO(%s): ", prefix, user)

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local new_line = line:sub(1, col) .. text .. line:sub(col + 1)
  vim.api.nvim_set_current_line(new_line)
  vim.api.nvim_win_set_cursor(0, { row, col + #text })
end

function M.input_todo()
  local input = require("remind-meh.input")
  input.open()
end

function M.get_username()
  return get_username()
end

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

function M.toggle()
  ui.toggle()
end

function M.open()
  ui.open()
end

function M.close()
  ui.close()
end

function M.refresh()
  ui.refresh()
end

function M.scan(opts)
  return scanner.scan(opts)
end

function M.scan_async(callback, opts)
  scanner.scan_async(callback, opts)
end

function M.get_todos()
  return scanner.get_cached()
end

function M.statusline()
  local statusline = require("remind-meh.statusline")
  return statusline.get_status()
end

function M.is_open()
  return ui.is_open()
end

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
