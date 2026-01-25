describe("scanner", function()
  local scanner = require("todos.scanner")
  local config = require("todos.config")

  before_each(function()
    config.setup({})
    scanner.cache = { results = {}, last_scan = 0 }
  end)

  describe("filter_by_keyword", function()
    it("filters results by keyword", function()
      local results = {
        { keyword = "TODO", file = "a.lua", line = 1, text = "todo item" },
        { keyword = "FIXME", file = "b.lua", line = 2, text = "fixme item" },
        { keyword = "TODO", file = "c.lua", line = 3, text = "another todo" },
      }

      local filtered = scanner.filter_by_keyword(results, "TODO")
      assert.equals(2, #filtered)
      assert.equals("TODO", filtered[1].keyword)
      assert.equals("TODO", filtered[2].keyword)
    end)

    it("returns all results when keyword is nil", function()
      local results = {
        { keyword = "TODO", file = "a.lua", line = 1, text = "todo item" },
        { keyword = "FIXME", file = "b.lua", line = 2, text = "fixme item" },
      }

      local filtered = scanner.filter_by_keyword(results, nil)
      assert.equals(2, #filtered)
    end)

    it("returns empty table when no matches", function()
      local results = {
        { keyword = "TODO", file = "a.lua", line = 1, text = "todo item" },
      }

      local filtered = scanner.filter_by_keyword(results, "BUG")
      assert.equals(0, #filtered)
    end)
  end)

  describe("count_by_keyword", function()
    it("counts results by keyword", function()
      local results = {
        { keyword = "TODO", file = "a.lua", line = 1, text = "todo item" },
        { keyword = "FIXME", file = "b.lua", line = 2, text = "fixme item" },
        { keyword = "TODO", file = "c.lua", line = 3, text = "another todo" },
        { keyword = "BUG", file = "d.lua", line = 4, text = "bug item" },
      }

      local counts = scanner.count_by_keyword(results)
      assert.equals(2, counts.TODO)
      assert.equals(1, counts.FIXME)
      assert.equals(1, counts.BUG)
    end)

    it("returns empty table for empty results", function()
      local counts = scanner.count_by_keyword({})
      assert.is_nil(counts.TODO)
    end)
  end)

  describe("get_cached", function()
    it("returns cached results", function()
      scanner.cache.results = {
        { keyword = "TODO", file = "a.lua", line = 1, text = "cached" },
      }

      local cached = scanner.get_cached()
      assert.equals(1, #cached)
      assert.equals("cached", cached[1].text)
    end)
  end)
end)
