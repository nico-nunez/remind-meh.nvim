describe("config", function()
  local config = require("remind-meh.config")

  before_each(function()
    -- Reset config state
    config.options = {}
  end)

  describe("defaults", function()
    it("has all required keywords", function()
      local defaults = config.defaults
      assert.is_not_nil(defaults.keywords.TODO)
      assert.is_not_nil(defaults.keywords.FIXME)
      assert.is_not_nil(defaults.keywords.HACK)
      assert.is_not_nil(defaults.keywords.NOTE)
      assert.is_not_nil(defaults.keywords.BUG)
      assert.is_not_nil(defaults.keywords.WARNING)
      assert.is_not_nil(defaults.keywords.IMPORTANT)
      assert.is_not_nil(defaults.keywords.XXX)
    end)

    it("has default keymaps", function()
      local defaults = config.defaults
      assert.equals("<leader>rl", defaults.keymap)
      assert.equals("<leader>ti", defaults.insert_keymap)
      assert.equals("<leader>tw", defaults.input_keymap)
      assert.equals("<leader>rn", defaults.next_keymap)
      assert.equals("<leader>rp", defaults.prev_keymap)
    end)

    it("has window defaults", function()
      local defaults = config.defaults
      assert.equals(0.6, defaults.window.width)
      assert.equals(0.5, defaults.window.height)
      assert.equals("rounded", defaults.window.border)
    end)
  end)

  describe("setup", function()
    it("merges user options with defaults", function()
      config.setup({ auto_open = false })
      local opts = config.get()
      assert.is_false(opts.auto_open)
      -- Should still have defaults
      assert.equals("<leader>rl", opts.keymap)
    end)

    it("deep merges nested options", function()
      config.setup({
        window = { width = 0.8 },
      })
      local opts = config.get()
      assert.equals(0.8, opts.window.width)
      -- Other window options should remain
      assert.equals(0.5, opts.window.height)
      assert.equals("rounded", opts.window.border)
    end)

    it("allows custom keywords", function()
      config.setup({
        keywords = {
          CUSTOM = { color = "#FF0000", icon = "!" },
        },
      })
      local opts = config.get()
      assert.is_not_nil(opts.keywords.CUSTOM)
      assert.equals("#FF0000", opts.keywords.CUSTOM.color)
    end)

    it("allows disabling keymaps", function()
      config.setup({ keymap = false })
      local opts = config.get()
      assert.is_false(opts.keymap)
    end)
  end)

  describe("get", function()
    it("returns defaults when not configured", function()
      local opts = config.get()
      assert.is_true(opts.auto_open)
    end)
  end)
end)
