---@meta

---@class KeywordConfig
---@field color string Hex color code (e.g., "#FF6B6B")
---@field icon string Nerd font icon

---@class AutoOpenFilters
---@field keywords KEYWORDS[] Keywords to filter on auto-open

---@class WindowConfig
---@field width number Window width (0-1 for percentage, >1 for columns)
---@field height number Window height (0-1 for percentage, >1 for rows)
---@field border string|string[] Border style ("rounded", "single", "double", etc.)

---@class ScannerConfig
---@field mode "accurate"|"fast" "accurate" uses tree-sitter validation, "fast" uses raw ripgrep

---@class RemindMehConfig
---@field keywords table<KEYWORDS, KeywordConfig> Keyword definitions with colors and icons
---@field exclude_dirs string[] Directories to exclude from scanning
---@field auto_open boolean Open reminder window on VimEnter
---@field auto_open_filters AutoOpenFilters Filters for auto-open feature
---@field keymap string Keymap to open reminder list
---@field insert_keymap string Keymap to insert inline TODO
---@field input_keymap string Keymap to open multi-line TODO input
---@field next_keymap string Keymap to jump to next TODO
---@field prev_keymap string Keymap to jump to previous TODO
---@field user string|nil Username for TODO attribution
---@field theme string Theme name or "custom"
---@field window WindowConfig Floating window configuration
---@field scanner ScannerConfig Scanner configuration
