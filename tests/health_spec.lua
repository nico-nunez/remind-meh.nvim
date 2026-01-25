describe("health", function()
  local health = require("todos.health")

  it("exports check function", function()
    assert.is_function(health.check)
  end)
end)
