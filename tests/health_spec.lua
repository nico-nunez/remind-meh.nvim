describe("health", function()
  local health = require("remind-meh.health")

  it("exports check function", function()
    assert.is_function(health.check)
  end)
end)
