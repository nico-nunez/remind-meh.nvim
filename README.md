# remind-meh.nvim

A fast, minimal Neovim plugin for tracking TODO comments in your codebase.

*"I'll get to it... meh, maybe later."*

## Features

- **Fast scanning** - Uses ripgrep when available (falls back to grep)
- **Accurate detection** - Tree-sitter validation ensures only comments are matched
- **Floating window UI** - Browse and jump to reminders with a centered popup
- **Keyword filtering** - Filter by TODO, FIXME, BUG, HACK, NOTE, XXX
- **Inline TODO insertion** - Insert TODOs at cursor with proper comment syntax
- **Multi-line input** - Popup window for longer TODO descriptions
- **Syntax highlighting** - Highlights TODO keywords in your buffers
- **Theme integration** - Adapts colors to your colorscheme (`theme = "auto"`)
- **Statusline integration** - Show reminder counts in your statusline
- **Async operations** - Non-blocking scans for large codebases

## Requirements

- Neovim >= 0.10
- [ripgrep](https://github.com/BurntSushi/ripgrep) (recommended, falls back to grep)
- Tree-sitter parsers for your languages (for accurate mode)

## Installation

### lazy.nvim

```lua
{
  "nico/remind-meh.nvim",
  config = function()
    require("remind-meh").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "nico/remind-meh.nvim",
  config = function()
    require("remind-meh").setup()
  end,
}
```

### vim-plug

```vim
Plug 'nico/remind-meh.nvim'

" In your init.lua or after/plugin:
lua require("remind-meh").setup()
```

## Configuration

Default configuration:

```lua
require("remind-meh").setup({
  -- Keywords to scan for (with colors and icons)
  keywords = {
    TODO  = { color = "#FFFF00", icon = "" },
    FIXME = { color = "#FF6B6B", icon = "" },
    HACK  = { color = "#FF9E64", icon = "" },
    NOTE  = { color = "#7DCFFF", icon = "" },
    BUG   = { color = "#F7768E", icon = "" },
    XXX   = { color = "#BB9AF7", icon = "" },
  },

  -- Directories to exclude from scanning
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

  -- Auto-open reminder list on startup if reminders are found
  auto_open = true,

  -- Keymaps (set to false to disable)
  keymap = "<leader>tl",        -- Toggle reminder list
  insert_keymap = "<leader>ti", -- Insert TODO at cursor
  input_keymap = "<leader>tw",  -- Open multi-line TODO input
  next_keymap = "<leader>tn",   -- Jump to next TODO in buffer
  prev_keymap = "<leader>tp",   -- Jump to previous TODO in buffer

  -- Username for TODO attribution (auto-detected from git or $USER)
  user = nil,

  -- Theme mode: "auto" adapts to colorscheme, "custom" uses keyword colors
  theme = "custom",

  -- Floating window dimensions
  window = {
    width = 0.6,    -- 60% of editor width
    height = 0.5,   -- 50% of editor height
    border = "rounded",
  },

  -- Scanner settings
  scanner = {
    mode = "accurate",  -- "accurate" | "fast"
  },
})
```

### Theme Integration

Set `theme = "auto"` to use colors from your colorscheme:

```lua
require("remind-meh").setup({
  theme = "auto",
})
```

This maps keywords to diagnostic/comment highlight groups for consistent theming.

### Scanner Mode

The scanner has two modes:

- **`"accurate"`** (default) - Uses tree-sitter to validate that matches are inside comments. Filters out false positives like `const foo = "TODO"`.
- **`"fast"`** - Raw ripgrep/grep results without validation. Faster on very large codebases but may include non-comment matches.

```lua
require("remind-meh").setup({
  scanner = {
    mode = "fast",  -- Skip tree-sitter validation
  },
})
```

For languages without tree-sitter support, matches are included regardless of mode.

## Commands

| Command | Description |
|---------|-------------|
| `:RemindMeh` | Open reminder list |
| `:RemindMehToggle` | Toggle reminder list |
| `:RemindMehClose` | Close reminder list |
| `:RemindMehRefresh` | Refresh reminder list |
| `:RemindMehInsert` | Insert TODO at cursor |
| `:RemindMehInput` | Open multi-line TODO input |
| `:RemindMehNext` | Jump to next TODO in buffer |
| `:RemindMehPrev` | Jump to previous TODO in buffer |

## Keymaps

### Default Keymaps

| Keymap | Action |
|--------|--------|
| `<leader>tl` | Toggle reminder list |
| `<leader>ti` | Insert TODO at cursor |
| `<leader>tw` | Open multi-line TODO input window |
| `<leader>tn` | Jump to next TODO in buffer |
| `<leader>tp` | Jump to previous TODO in buffer |

### Reminder List Window

| Key | Action |
|-----|--------|
| `<CR>` | Jump to location |
| `f` | Filter by keyword |
| `r` | Refresh list |
| `q` / `<Esc>` | Close window |

### Multi-line Input Window

| Key | Action |
|-----|--------|
| `<C-CR>` (insert) | Submit TODO |
| `<CR>` (normal) | Submit TODO |
| `q` / `<Esc>` | Cancel |

## Statusline Integration

Add reminder counts to your statusline:

```lua
-- Basic usage (returns formatted string like " 5  2  1")
require("remind-meh").statusline()

-- Detailed format (returns "TODO: 5 | FIXME: 2 | BUG: 1")
require("remind-meh.statusline").get_status_detailed()

-- Just the count
require("remind-meh.statusline").get_count()
```

### lualine.nvim example

```lua
require("lualine").setup({
  sections = {
    lualine_x = {
      function() return require("remind-meh").statusline() end,
      "encoding",
      "fileformat",
      "filetype",
    },
  },
})
```

> **Note:** Defining `sections.lualine_x` overrides lualine's defaults for that section.
> The example above includes `encoding`, `fileformat`, and `filetype` to preserve
> common defaults. Adjust based on what you want displayed.

## API

```lua
local remind_meh = require("remind-meh")

-- UI
remind_meh.open()           -- Open reminder list
remind_meh.close()          -- Close reminder list
remind_meh.toggle()         -- Toggle reminder list
remind_meh.refresh()        -- Refresh reminder list
remind_meh.is_open()        -- Check if window is open

-- Scanning
remind_meh.scan()           -- Synchronous scan (returns results)
remind_meh.scan_async(cb)   -- Async scan (calls cb with results)
remind_meh.get_todos()      -- Get cached results

-- Insertion
remind_meh.insert_todo()    -- Insert TODO at cursor
remind_meh.input_todo()     -- Open multi-line input window

-- Navigation
remind_meh.next_todo()      -- Jump to next TODO in buffer
remind_meh.prev_todo()      -- Jump to previous TODO in buffer

-- Statusline
remind_meh.statusline()     -- Get formatted status string
```

## Health Check

Run `:checkhealth remind-meh` to verify your setup.

## Development

### Running Tests

Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim):

```bash
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
```

### Linting

```bash
stylua --check lua/ tests/
```

## License

MIT
