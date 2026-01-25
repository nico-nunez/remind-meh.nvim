local M = {}

M.defaults = {
  keywords = {
    TODO = { color = "#FFFF00", icon = "" },
    FIXME = { color = "#FF6B6B", icon = "" },
    HACK = { color = "#FF9E64", icon = "" },
    NOTE = { color = "#7DCFFF", icon = "" },
    BUG = { color = "#F7768E", icon = "" },
    XXX = { color = "#BB9AF7", icon = "" },
  },
  exclude_dirs = {
    ".git",
    "node_modules",
    "vendor",
    "build",
    "dist",
    ".next",
    "__pycache__",
    ".venv",
    "target",
  },
  auto_open = true,
  keymap = "<leader>tl",
  insert_keymap = "<leader>ti",
  input_keymap = "<leader>tw",
  next_keymap = "<leader>tn",
  prev_keymap = "<leader>tp",
  user = nil,
  theme = "custom",
  window = {
    width = 0.6,
    height = 0.5,
    border = "rounded",
  },
}

M.options = {}

local function deep_merge(t1, t2)
  local result = vim.deepcopy(t1)
  for k, v in pairs(t2) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = deep_merge(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

function M.setup(opts)
  M.options = deep_merge(M.defaults, opts or {})
  return M.options
end

function M.get()
  if vim.tbl_isempty(M.options) then
    return M.defaults
  end
  return M.options
end

return M
