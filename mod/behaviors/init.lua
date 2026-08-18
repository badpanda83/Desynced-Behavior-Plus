local attack_unit = require("mod.behaviors.attack_unit")

local M = {}

function M.register_all(registry)
  if registry and registry.register_behavior then
    registry.register_behavior(attack_unit)
  end
end

return M
