-- spawn_encounter.lua
-- Behavior: Spawn Test Encounter
--
-- Spawns a hostile encounter (alien or bug swarm) on demand so players can
-- validate automated defenses without waiting for a natural wave.
--
-- Inputs:
--   spawn_point  (position, required)  – world position to spawn hostiles at
--   species      (string,   optional)  – "alien" (default) | "bug_swarm"
--   difficulty   (number,   optional)  – 1 (easy) to 5 (nightmare), default 1
--
-- Difficulty scaling:
--   1 = 2 units,  tier 1,  base health multiplier 1.0
--   2 = 4 units,  tier 1,  health ×1.5
--   3 = 6 units,  tier 2,  health ×2.0
--   4 = 8 units,  tier 2,  health ×3.0
--   5 = 12 units, tier 3,  health ×4.0
--
-- Usage example (from a behavior registry / debug console):
--   local ctx = {
--     spawn_point = { x = 100, y = 200 },
--     species = "bug_swarm",
--     difficulty = 3,
--     command = { spawn_hostile = function(unit_type, pos, opts) ... end },
--   }
--   SpawnEncounter.execute(ctx)

local SpawnEncounter = {
  id = "spawn_encounter",
  name = "Spawn Test Encounter",
  description = "Spawns a hostile encounter for testing automated defenses.",
  inputs = {
    { key = "spawn_point", type = "position", required = true },
    { key = "species",     type = "string",   required = false, default = "alien" },
    { key = "difficulty",  type = "number",   required = false, default = 1 },
  },
}

-- Valid species identifiers understood by the encounter system.
SpawnEncounter.SPECIES = {
  alien    = "alien",
  bug_swarm = "bug_swarm",
}

-- Per-difficulty parameters: { unit_count, tier, health_multiplier }
local DIFFICULTY_TABLE = {
  [1] = { count = 2,  tier = 1, health_mult = 1.0 },
  [2] = { count = 4,  tier = 1, health_mult = 1.5 },
  [3] = { count = 6,  tier = 2, health_mult = 2.0 },
  [4] = { count = 8,  tier = 2, health_mult = 3.0 },
  [5] = { count = 12, tier = 3, health_mult = 4.0 },
}

--- Returns the difficulty parameter row, clamped to the valid range 1-5.
local function resolve_difficulty(difficulty)
  local level = math.floor(tonumber(difficulty) or 1)
  if level < 1 then level = 1 end
  if level > 5 then level = 5 end
  return DIFFICULTY_TABLE[level]
end

--- Validates inputs and returns ok, error_message.
function SpawnEncounter.validate(ctx)
  if not ctx then return false, "missing context" end
  if not ctx.spawn_point then return false, "missing spawn_point" end

  -- Validate species (coerce nil to default).
  local species = ctx.species or "alien"
  if not SpawnEncounter.SPECIES[species] then
    return false, "unknown species '" .. tostring(species) ..
      "'; valid values: alien, bug_swarm"
  end

  -- Validate difficulty range (nil is fine, will be defaulted).
  if ctx.difficulty ~= nil then
    local d = tonumber(ctx.difficulty)
    if not d then return false, "difficulty must be a number" end
  end

  return true
end

--- Executes the encounter spawn.
-- Attempts to use ctx.command.spawn_hostile when available; falls back to a
-- ctx.spawn_hostile direct call for alternate environments.
function SpawnEncounter.execute(ctx)
  local ok, err = SpawnEncounter.validate(ctx)
  if not ok then
    return false, err
  end

  local species    = SpawnEncounter.SPECIES[ctx.species or "alien"]
  local params     = resolve_difficulty(ctx.difficulty or 1)
  local spawn_pos  = ctx.spawn_point

  local opts = {
    count        = params.count,
    tier         = params.tier,
    health_mult  = params.health_mult,
  }

  -- Primary path: structured command table (mirrors attack_unit pattern).
  if ctx.command and ctx.command.spawn_hostile then
    for _ = 1, opts.count do
      ctx.command.spawn_hostile(species, spawn_pos, opts)
    end
    return true
  end

  -- Fallback: direct spawn function on ctx.
  if ctx.spawn_hostile then
    for _ = 1, opts.count do
      ctx.spawn_hostile(species, spawn_pos, opts)
    end
    return true
  end

  return false, "no compatible spawn command found"
end

return SpawnEncounter
