local M = {}

local KEYWORDS = require("remind-meh.constants").KEYWORDS

---@type RemindMehConfig
M.defaults = {
  keywords = {
    TODO = { color = "#FFFF00", icon = "" },
    FIXME = { color = "#FF6B6B", icon = "" },
    HACK = { color = "#FF9E64", icon = "" },
    NOTE = { color = "#7DCFFF", icon = "" },
    BUG = { color = "#F7768E", icon = "" },
    WARNING = { color = "#FF9E64", icon = "" },
    IMPORTANT = { color = "#F7768E", icon = "" },
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
  default_filters = {
    keywords = { KEYWORDS.TODO, KEYWORDS.FIXME, KEYWORDS.BUG }
  },
  keymap = "<leader>rl",
  insert_keymap = "<leader>ti",
  input_keymap = "<leader>tw",
  next_keymap = "<leader>rn",
  prev_keymap = "<leader>rp",
  user = nil,
  theme = "custom",
  window = {
    width = 0.6,
    height = 0.5,
    border = "rounded",
  },
  scanner = {
    mode = "accurate", -- "accurate" (tree-sitter validation) | "fast" (raw ripgrep)
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

---@param opts RemindMehConfig|nil
function M.setup(opts)
  opts = opts or {}
  local user_exclude_dirs = opts.exclude_dirs or {}
  M.options = deep_merge(M.defaults, opts)
  -- Extend defaults with user-provided dirs rather than replacing them
  local combined = vim.deepcopy(M.defaults.exclude_dirs)
  for _, dir in ipairs(user_exclude_dirs) do
    if not vim.tbl_contains(combined, dir) then
      table.insert(combined, dir)
    end
  end
  M.options.exclude_dirs = combined
  return M.options
end

function M.get()
  if vim.tbl_isempty(M.options) then
    return M.defaults
  end
  return M.options
end

return M
