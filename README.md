# todos.nvim

A fast, minimal Neovim plugin for tracking TODO comments in your codebase.

## Features

- **Fast scanning** - Uses ripgrep when available (falls back to grep)
- **Floating window UI** - Browse and jump to TODOs with a centered popup
- **Keyword filtering** - Filter by TODO, FIXME, BUG, HACK, NOTE, XXX
- **Inline TODO insertion** - Insert TODOs at cursor with proper comment syntax
- **Multi-line input** - Popup window for longer TODO descriptions
- **Syntax highlighting** - Highlights TODO keywords in your buffers
- **Theme integration** - Adapts colors to your colorscheme (`theme = "auto"`)
- **Statusline integration** - Show TODO counts in your statusline
- **Async operations** - Non-blocking scans for large codebases

## Requirements

- Neovim >= 0.9
- [ripgrep](https://github.com/BurntSushi/ripgrep) (recommended, falls back to grep)

## Installation

### lazy.nvim

```lua
{
  "nico/todos.nvim",
  config = function()
    require("todos").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "nico/todos.nvim",
  config = function()
    require("todos").setup()
  end,
}
```

### vim-plug

```vim
Plug 'nico/todos.nvim'

" In your init.lua or after/plugin:
lua require("todos").setup()
```

## Configuration

Default configuration:

```lua
require("todos").setup({
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

  -- Auto-open TODO list on startup if TODOs are found
  auto_open = true,

  -- Keymaps (set to false to disable)
  keymap = "<leader>tl",        -- Toggle TODO list
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
})
```

### Theme Integration

Set `theme = "auto"` to use colors from your colorscheme:

```lua
require("todos").setup({
  theme = "auto",
})
```

This maps keywords to diagnostic/comment highlight groups for consistent theming.

## Commands

| Command | Description |
|---------|-------------|
| `:Todos` | Open TODO list |
| `:TodosToggle` | Toggle TODO list |
| `:TodosClose` | Close TODO list |
| `:TodosRefresh` | Refresh TODO list |
| `:TodosInsert` | Insert TODO at cursor |
| `:TodosInput` | Open multi-line TODO input |
| `:TodosNext` | Jump to next TODO in buffer |
| `:TodosPrev` | Jump to previous TODO in buffer |

## Keymaps

### Default Keymaps

| Keymap | Action |
|--------|--------|
| `<leader>tl` | Toggle TODO list |
| `<leader>ti` | Insert TODO at cursor |
| `<leader>tw` | Open multi-line TODO input window |
| `<leader>tn` | Jump to next TODO in buffer |
| `<leader>tp` | Jump to previous TODO in buffer |

### TODO List Window

| Key | Action |
|-----|--------|
| `<CR>` | Jump to TODO location |
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

Add TODO counts to your statusline:

```lua
-- Basic usage (returns formatted string like " 5  2  1")
require("todos").statusline()

-- Detailed format (returns "TODO: 5 | FIXME: 2 | BUG: 1")
require("todos.statusline").get_status_detailed()

-- Just the count
require("todos.statusline").get_count()
```

### lualine.nvim example

```lua
require("lualine").setup({
  sections = {
    lualine_x = {
      { function() return require("todos").statusline() end },
    },
  },
})
```

## API

```lua
local todos = require("todos")

-- UI
todos.open()           -- Open TODO list
todos.close()          -- Close TODO list
todos.toggle()         -- Toggle TODO list
todos.refresh()        -- Refresh TODO list
todos.is_open()        -- Check if window is open

-- Scanning
todos.scan()           -- Synchronous scan (returns results)
todos.scan_async(cb)   -- Async scan (calls cb with results)
todos.get_todos()      -- Get cached results

-- Insertion
todos.insert_todo()    -- Insert TODO at cursor
todos.input_todo()     -- Open multi-line input window

-- Navigation
todos.next_todo()      -- Jump to next TODO in buffer
todos.prev_todo()      -- Jump to previous TODO in buffer

-- Statusline
todos.statusline()     -- Get formatted status string
```

## Health Check

Run `:checkhealth todos` to verify your setup.

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
