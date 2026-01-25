local M = {}

local config = require("remind-meh.config")

local state = {
  buf = nil,
  win = nil,
  original_pos = nil,
  original_buf = nil,
}

local function get_username()
  local remind_meh = require("remind-meh")
  return remind_meh.get_username()
end

local function get_comment_prefix(bufnr)
  local comment = vim.bo[bufnr].commentstring
  if comment == "" or comment == nil then
    comment = "// %s"
  end
  local prefix = comment:gsub("%%s", ""):gsub("%s*$", "")
  if prefix ~= "" then
    prefix = prefix .. " "
  end
  return prefix
end

local function close_window()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  state.win = nil
  state.buf = nil
end

local function submit()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
  local original_buf = state.original_buf
  local original_pos = state.original_pos

  close_window()

  if not original_buf or not vim.api.nvim_buf_is_valid(original_buf) then
    return
  end

  local non_empty = {}
  for _, line in ipairs(lines) do
    if line:match("%S") then
      table.insert(non_empty, line)
    end
  end

  if #non_empty == 0 then
    return
  end

  local prefix = get_comment_prefix(original_buf)
  local user = get_username()

  local result_lines = {}
  for i, line in ipairs(non_empty) do
    if i == 1 then
      table.insert(result_lines, string.format("%sTODO(%s): %s", prefix, user, line))
    else
      table.insert(result_lines, string.format("%s  %s", prefix, line))
    end
  end

  local row = original_pos[1]
  vim.api.nvim_buf_set_lines(original_buf, row - 1, row - 1, false, result_lines)
end

local function cancel()
  close_window()
end

function M.open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_set_current_win(state.win)
    return
  end

  state.original_buf = vim.api.nvim_get_current_buf()
  state.original_pos = vim.api.nvim_win_get_cursor(0)

  local opts = config.get()
  local width = math.floor(vim.o.columns * 0.6)
  local height = 8
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].buftype = "nofile"
  vim.bo[state.buf].bufhidden = "wipe"
  vim.bo[state.buf].swapfile = false

  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = opts.window and opts.window.border or "rounded",
    title = " Reminder Input ",
    title_pos = "center",
  })

  vim.wo[state.win].wrap = true
  vim.wo[state.win].cursorline = true

  vim.keymap.set("i", "<C-CR>", function()
    vim.cmd("stopinsert")
    submit()
  end, { buffer = state.buf, silent = true })

  vim.keymap.set("n", "<CR>", submit, { buffer = state.buf, silent = true })
  vim.keymap.set("n", "q", cancel, { buffer = state.buf, silent = true })
  vim.keymap.set("n", "<Esc>", cancel, { buffer = state.buf, silent = true })
  vim.keymap.set("i", "<Esc>", cancel, { buffer = state.buf, silent = true })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = state.buf,
    once = true,
    callback = close_window,
  })

  vim.cmd("startinsert")
end

function M.close()
  close_window()
end

return M
