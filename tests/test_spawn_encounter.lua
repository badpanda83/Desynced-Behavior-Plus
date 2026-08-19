-- tests/test_spawn_encounter.lua
-- Lightweight validation for SpawnEncounter behavior.
-- Run with: lua tests/test_spawn_encounter.lua
--
-- Each test calls assert() so failures are immediately visible with a clear
-- message. The test suite mirrors the style of validating ctx inputs used by
-- attack_unit.lua.

-- Adjust require path so the script can be run from the repo root.
package.path = package.path .. ";./mod/?.lua;./mod/behaviors/?.lua"

local SpawnEncounter = require("mod.behaviors.spawn_encounter")

local pass = 0
local fail = 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("[PASS] " .. name)
    pass = pass + 1
  else
    print("[FAIL] " .. name .. " -- " .. tostring(err))
    fail = fail + 1
  end
end

-- ── validate() tests ────────────────────────────────────────────────────────

test("validate: nil ctx returns false", function()
  local ok, _ = SpawnEncounter.validate(nil)
  assert(ok == false)
end)

test("validate: missing spawn_point returns false", function()
  local ok, _ = SpawnEncounter.validate({ species = "alien", difficulty = 1 })
  assert(ok == false)
end)

test("validate: unknown species returns false", function()
  local ok, msg = SpawnEncounter.validate({
    spawn_point = { x = 0, y = 0 },
    species = "dragon",
  })
  assert(ok == false)
  assert(msg:find("unknown species"))
end)

test("validate: non-numeric difficulty returns false", function()
  local ok, _ = SpawnEncounter.validate({
    spawn_point = { x = 0, y = 0 },
    difficulty = "hard",
  })
  assert(ok == false)
end)

test("validate: valid alien ctx returns true", function()
  local ok, _ = SpawnEncounter.validate({
    spawn_point = { x = 10, y = 20 },
    species = "alien",
    difficulty = 3,
  })
  assert(ok == true)
end)

test("validate: valid bug_swarm ctx returns true", function()
  local ok, _ = SpawnEncounter.validate({
    spawn_point = { x = 0, y = 0 },
    species = "bug_swarm",
  })
  assert(ok == true)
end)

test("validate: nil species defaults (no error)", function()
  local ok, _ = SpawnEncounter.validate({
    spawn_point = { x = 0, y = 0 },
  })
  assert(ok == true)
end)

-- ── execute() tests ──────────────────────────────────────────────────────────

test("execute: no command returns false", function()
  local ok, _ = SpawnEncounter.execute({
    spawn_point = { x = 0, y = 0 },
    species = "alien",
    difficulty = 1,
  })
  assert(ok == false)
end)

test("execute: command.spawn_hostile called correct count (difficulty 1)", function()
  local calls = 0
  local ctx = {
    spawn_point = { x = 5, y = 5 },
    species = "alien",
    difficulty = 1,
    command = {
      spawn_hostile = function(species, pos, opts)
        calls = calls + 1
      end,
    },
  }
  local ok, _ = SpawnEncounter.execute(ctx)
  assert(ok == true)
  assert(calls == 2, "expected 2 spawns at difficulty 1, got " .. calls)
end)

test("execute: difficulty 5 spawns 12 units", function()
  local calls = 0
  local ctx = {
    spawn_point = { x = 0, y = 0 },
    species = "bug_swarm",
    difficulty = 5,
    command = {
      spawn_hostile = function() calls = calls + 1 end,
    },
  }
  local ok, _ = SpawnEncounter.execute(ctx)
  assert(ok == true)
  assert(calls == 12, "expected 12 spawns at difficulty 5, got " .. calls)
end)

test("execute: difficulty clamped below 1 behaves as difficulty 1", function()
  local calls = 0
  local ctx = {
    spawn_point = { x = 0, y = 0 },
    species = "alien",
    difficulty = -99,
    command = {
      spawn_hostile = function() calls = calls + 1 end,
    },
  }
  local ok, _ = SpawnEncounter.execute(ctx)
  assert(ok == true)
  assert(calls == 2)
end)

test("execute: difficulty clamped above 5 behaves as difficulty 5", function()
  local calls = 0
  local ctx = {
    spawn_point = { x = 0, y = 0 },
    species = "bug_swarm",
    difficulty = 999,
    command = {
      spawn_hostile = function() calls = calls + 1 end,
    },
  }
  local ok, _ = SpawnEncounter.execute(ctx)
  assert(ok == true)
  assert(calls == 12)
end)

test("execute: opts contain tier and health_mult", function()
  local received_opts
  local ctx = {
    spawn_point = { x = 0, y = 0 },
    species = "alien",
    difficulty = 3,
    command = {
      spawn_hostile = function(_, _, opts) received_opts = opts end,
    },
  }
  SpawnEncounter.execute(ctx)
  assert(received_opts ~= nil)
  assert(received_opts.tier == 2)
  assert(received_opts.health_mult == 2.0)
end)

test("execute: fallback ctx.spawn_hostile path works", function()
  local calls = 0
  local ctx = {
    spawn_point = { x = 0, y = 0 },
    species = "bug_swarm",
    difficulty = 2,
    spawn_hostile = function() calls = calls + 1 end,
  }
  local ok, _ = SpawnEncounter.execute(ctx)
  assert(ok == true)
  assert(calls == 4)
end)

-- ── summary ─────────────────────────────────────────────────────────────────

print(string.format("\n%d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
