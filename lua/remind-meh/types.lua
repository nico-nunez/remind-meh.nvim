---@meta

---@class KeywordConfig
---@field color string Hex color code (e.g., "#FF6B6B")
---@field icon string Nerd font icon

---@alias KeywordConfigs table<KEYWORDS, KeywordConfig>

---@class AutoOpenFilters
---@field keywords KEYWORDS[] Keywords to filter on auto-open

---@class WindowConfig
---@field width? number Window width (0-1 for percentage, >1 for columns)
---@field height? number Window height (0-1 for percentage, >1 for rows)
---@field border? string|string[] Border style ("rounded", "single", "double", etc.)

---@class ScannerConfig
---@field mode? "accurate"|"fast" "accurate" uses tree-sitter validation, "fast" uses raw ripgrep

---@class RemindMehConfig
---@field keywords? KeywordConfigs Keyword definitions with colors and icons
---@field exclude_dirs? string[] Additional directories to exclude from scanning (extends defaults, not replaces)
---@field auto_open? boolean Open reminder window on VimEnter
---@field default_filters? AutoOpenFilters Filters for auto-open feature
---@field keymap? string Keymap to open reminder list
---@field insert_keymap? string Keymap to insert inline TODO
---@field input_keymap? string Keymap to open multi-line TODO input
---@field next_keymap? string Keymap to jump to next TODO
---@field prev_keymap? string Keymap to jump to previous TODO
---@field user? string Username for TODO attribution
---@field theme? string Theme name or "custom"
---@field window? WindowConfig Floating window configuration
---@field scanner? ScannerConfig Scanner configuration

---@class ParsedResult
---@field file string The filename of result
---@field line number The line number of result
---@field col number The column number of result
---@field keyword KEYWORDS The keyword that was searched
---@field text string The text associated with keyword

---@class ScanOpts
---@field cwd? string Directory to scan (defaults to vim.fn.getcwd())

---@alias KeywordCounts table<string, integer>

---@class WindowDimensions
---@field width integer
---@field height integer
---@field row integer
---@field col integer

---@class UIState
---@field win integer|nil Floating window handle
---@field buf integer|nil Buffer handle
---@field results ParsedResult[] Full unfiltered scan results
---@field filtered_results ParsedResult[] Currently displayed (possibly filtered) results
---@field current_filter string|nil Active keyword filter, nil means show all
