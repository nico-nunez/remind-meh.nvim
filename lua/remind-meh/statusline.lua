local M = {}

local scanner = require("remind-meh.scanner")
local config = require("remind-meh.config")

M.cache = {
  status = "",
  last_update = 0,
  update_interval = 30000,
}

local function format_status(results)
  if #results == 0 then
    return ""
  end

  local cfg = config.get()
  local counts = scanner.count_by_keyword(results)

  local todo_count = counts.TODO or 0
  local fixme_count = counts.FIXME or 0
  local bug_count = counts.BUG or 0

  local parts = {}

  if todo_count > 0 then
    local icon = cfg.keywords.TODO and cfg.keywords.TODO.icon or ""
    table.insert(parts, icon .. " " .. todo_count)
  end

  if fixme_count > 0 then
    local icon = cfg.keywords.FIXME and cfg.keywords.FIXME.icon or ""
    table.insert(parts, icon .. " " .. fixme_count)
  end

  if bug_count > 0 then
    local icon = cfg.keywords.BUG and cfg.keywords.BUG.icon or ""
    table.insert(parts, icon .. " " .. bug_count)
  end

  if #parts == 0 then
    return " " .. #results
  end

  return table.concat(parts, " ")
end

function M.get_status()
  local now = vim.loop.now()

  if now - M.cache.last_update < M.cache.update_interval and M.cache.status ~= "" then
    return M.cache.status
  end

  local results = scanner.get_cached()
  if #results == 0 then
    results = scanner.scan()
  end

  M.cache.status = format_status(results)
  M.cache.last_update = now

  return M.cache.status
end

function M.get_status_detailed()
  local results = scanner.get_cached()
  if #results == 0 then
    results = scanner.scan()
  end

  local counts = scanner.count_by_keyword(results)
  local cfg = config.get()
  local parts = {}

  for keyword, count in pairs(counts) do
    if count > 0 then
      local icon = cfg.keywords[keyword] and cfg.keywords[keyword].icon or ""
      table.insert(parts, string.format("%s %s: %d", icon, keyword, count))
    end
  end

  return table.concat(parts, " | ")
end

function M.get_count()
  local results = scanner.get_cached()
  return #results
end

function M.refresh()
  scanner.scan_async(function(results)
    M.cache.status = format_status(results)
    M.cache.last_update = vim.loop.now()
  end)
end

local function setup_refresh_autocmd()
  local group = vim.api.nvim_create_augroup("RemindMehStatusline", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function()
      M.refresh()
    end,
    desc = "Refresh remind-meh statusline on save",
  })
end

setup_refresh_autocmd()

return M
