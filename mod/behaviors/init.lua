local attack_unit       = require("mod.behaviors.attack_unit")
local spawn_encounter   = require("mod.behaviors.spawn_encounter")

local M = {}

function M.register_all(registry)
  if registry and registry.register_behavior then
    registry.register_behavior(attack_unit)
    -- Test-defense encounter spawner (see spawn_encounter.lua for usage).
    registry.register_behavior(spawn_encounter)
  end
end

return M
