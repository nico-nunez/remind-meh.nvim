local M = {}

local config = require("remind-meh.config")
local validator = require("remind-meh.validator")

M.cache = {
  results = {},
  last_scan = 0,
}

local function has_ripgrep()
  return vim.fn.executable("rg") == 1
end

---@param keywords KeywordConfigs
---@return string
local function build_pattern(keywords)
  local patterns = {}
  for keyword, _ in pairs(keywords) do
    table.insert(patterns, keyword .. [[\s*(\(.*\))?\s*:]])
  end
  return table.concat(patterns, "|")
end

---@param exclude_dirs string[]
---@param use_rg boolean
---@return string[]
local function build_exclude_args(exclude_dirs, use_rg)
  local args = {}
  for _, dir in ipairs(exclude_dirs) do
    if use_rg then
      table.insert(args, "--glob")
      table.insert(args, "!" .. dir)
    else
      table.insert(args, "--exclude-dir=" .. dir)
    end
  end
  return args
end

---Parses output string and check for keywords.
---@param line string Output string to be parsed
---@param keywords KeywordConfigs Keyword to search for
---@return ParsedResult | nil result Returns ParsedResult or nil
local function parse_result(line, keywords)
  local file, lnum, col, text = line:match("^(.+):(%d+):(%d+):(.*)$")
  if not file then
    file, lnum, text = line:match("^(.+):(%d+):(.*)$")
    col = "1"
  end

  if not file then
    return nil
  end

  local keyword = nil
  for kw, _ in pairs(keywords) do
    if text:match(kw .. "%s*[%(%:]") or text:match(kw .. ":") then
      keyword = kw
      break
    end
  end

  if not keyword then
    for kw, _ in pairs(keywords) do
      if text:match(kw) then
        keyword = kw
        break
      end
    end
  end

  return {
    file = file,
    line = tonumber(lnum),
    col = tonumber(col) or 1,
    keyword = keyword or "TODO",
    text = vim.trim(text),
  }
end

---Synchronously scans for TODO keywords using rg or grep and returns parsed results.
---@param opts? ScanOpts
---@return ParsedResult[]
function M.scan(opts)
  opts = opts or {}
  local cfg = config.get()
  local cwd = opts.cwd or vim.fn.getcwd()
  local keywords = cfg.keywords

  local pattern = build_pattern(keywords)
  local use_rg = has_ripgrep()
  local exclude_args = build_exclude_args(cfg.exclude_dirs, use_rg)

  local cmd
  if use_rg then
    cmd = { "rg", "--vimgrep", "--no-heading", "-e", pattern }
    vim.list_extend(cmd, exclude_args)
    table.insert(cmd, cwd)
  else
    cmd = { "grep", "-rn", "-E", pattern }
    vim.list_extend(cmd, exclude_args)
    table.insert(cmd, cwd)
  end

  local results = {}
  local output = vim.fn.systemlist(cmd)

  if vim.v.shell_error > 1 then
    return results
  end

  for _, line in ipairs(output) do
    local parsed = parse_result(line, keywords)
    if parsed then
      table.insert(results, parsed)
    end
  end

  results = validator.validate(results)

  M.cache.results = results
  M.cache.last_scan = vim.loop.now()

  return results
end

---Asynchronously scans for TODO keywords and calls callback with parsed results.
---@param callback fun(results: ParsedResult[])
---@param opts? ScanOpts
function M.scan_async(callback, opts)
  opts = opts or {}
  local cfg = config.get()
  local cwd = opts.cwd or vim.fn.getcwd()
  local keywords = cfg.keywords

  local pattern = build_pattern(keywords)
  local use_rg = has_ripgrep()
  local exclude_args = build_exclude_args(cfg.exclude_dirs, use_rg)

  local cmd
  if use_rg then
    cmd = { "rg", "--vimgrep", "--no-heading", "-e", pattern }
    vim.list_extend(cmd, exclude_args)
    table.insert(cmd, cwd)
  else
    cmd = { "grep", "-rn", "-E", pattern }
    vim.list_extend(cmd, exclude_args)
    table.insert(cmd, cwd)
  end

  local results = {}
  local stdout_data = {}

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout_data, data)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code <= 1 then
        for _, line in ipairs(stdout_data) do
          if line and line ~= "" then
            local parsed = parse_result(line, keywords)
            if parsed then
              table.insert(results, parsed)
            end
          end
        end
      end

      results = validator.validate(results)

      M.cache.results = results
      M.cache.last_scan = vim.loop.now()

      if callback then
        vim.schedule(function()
          callback(results)
        end)
      end
    end,
  })
end

---Returns the results from the most recent scan without re-scanning.
---@return ParsedResult[]
function M.get_cached()
  return M.cache.results
end

---Filters results to only those matching the given keyword. Returns all if keyword is nil.
---@param results ParsedResult[]
---@param keyword string|nil
---@return ParsedResult[]
function M.filter_by_keyword(results, keyword)
  if not keyword then
    return results
  end

  local filtered = {}
  for _, item in ipairs(results) do
    if item.keyword == keyword then
      table.insert(filtered, item)
    end
  end
  return filtered
end

---Returns a map of keyword -> count for the given results.
---@param results ParsedResult[]
---@return KeywordCounts
function M.count_by_keyword(results)
  local counts = {}
  for _, item in ipairs(results) do
    counts[item.keyword] = (counts[item.keyword] or 0) + 1
  end
  return counts
end

return M
