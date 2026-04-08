local M = {}

local config = require("remind-meh.config")

local extension_to_lang = {
  lua = "lua",
  py = "python",
  js = "javascript",
  jsx = "javascript",
  ts = "typescript",
  tsx = "tsx",
  rb = "ruby",
  rs = "rust",
  go = "go",
  c = "c",
  h = "c",
  cpp = "cpp",
  hpp = "cpp",
  cc = "cpp",
  java = "java",
  kt = "kotlin",
  swift = "swift",
  php = "php",
  sh = "bash",
  bash = "bash",
  zsh = "bash",
  vim = "vim",
  html = "html",
  css = "css",
  scss = "scss",
  json = "json",
  yaml = "yaml",
  yml = "yaml",
  toml = "toml",
  md = "markdown",
  ex = "elixir",
  exs = "elixir",
  erl = "erlang",
  hs = "haskell",
  ml = "ocaml",
  cs = "c_sharp",
  fs = "fsharp",
  r = "r",
  sql = "sql",
  graphql = "graphql",
  vue = "vue",
  svelte = "svelte",
}

local function get_lang_from_file(file)
  local ext = vim.fn.fnamemodify(file, ":e")
  return extension_to_lang[ext]
end

local function is_in_comment(file, line, col, file_cache)
  local lang = get_lang_from_file(file)
  if not lang then
    return true -- No language mapping, include the match
  end

  local ok, parser_exists = pcall(vim.treesitter.language.inspect, lang)
  if not ok or not parser_exists then
    return true -- No tree-sitter parser, include the match
  end

  -- Use cached content or read file
  local content = file_cache[file]
  if not content then
    local lines = vim.fn.readfile(file)
    if not lines or #lines == 0 then
      return true
    end
    content = table.concat(lines, "\n")
    file_cache[file] = content
  end

  local parse_ok, parser = pcall(vim.treesitter.get_string_parser, content, lang)
  if not parse_ok or not parser then
    return true -- Parser creation failed, include the match
  end

  local tree_ok, trees = pcall(function()
    return parser:parse()
  end)
  if not tree_ok or not trees or not trees[1] then
    return true
  end

  local tree = trees[1]
  local root = tree:root()

  -- line is 1-indexed from ripgrep, tree-sitter uses 0-indexed
  local ts_line = line - 1
  local ts_col = col - 1

  local node = root:named_descendant_for_range(ts_line, ts_col, ts_line, ts_col)

  while node do
    local node_type = node:type()
    if node_type:match("comment") then
      return true
    end
    node = node:parent()
  end

  return false
end

---Filters results to only those inside comment nodes using tree-sitter.
---Falls back to including the result if language/parser is unavailable.
---In "fast" scanner mode, returns results unchanged.
---@param results ParsedResult[]
---@return ParsedResult[]
function M.validate(results)
  local cfg = config.get()
  if cfg.scanner.mode ~= "accurate" then
    return results
  end

  local validated = {}
  local file_cache = {} -- Cache file content to avoid re-reading

  for _, item in ipairs(results) do
    if is_in_comment(item.file, item.line, item.col, file_cache) then
      table.insert(validated, item)
    end
  end

  return validated
end

return M
