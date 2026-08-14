-- tests/self_check.lua
-- Standalone self-check / test script for BehaviorEasyWay.
--
-- Run with a plain Lua 5.4 interpreter from the repository root:
--   lua tests/self_check.lua
--
-- Exit code 0 = all checks passed.
-- Exit code 1 = one or more checks failed.

-- ---------------------------------------------------------------------------
-- Path setup so require() works from repo root
-- ---------------------------------------------------------------------------
package.path = "./?.lua;./?/init.lua;" .. package.path

local generator = require("src.core.generator")
local validator = require("src.validators.behavior_validator")

-- ---------------------------------------------------------------------------
-- Minimal test harness
-- ---------------------------------------------------------------------------

local passed = 0
local failed = 0

local function check(name, cond, detail)
    if cond then
        print(string.format("[PASS] %s", name))
        passed = passed + 1
    else
        print(string.format("[FAIL] %s – %s", name, tostring(detail or "assertion failed")))
        failed = failed + 1
    end
end

local function check_eq(name, got, expected)
    if got == expected then
        check(name, true)
    else
        check(name, false, string.format("expected %q, got %q", tostring(expected), tostring(got)))
    end
end

-- ---------------------------------------------------------------------------
-- 1. Template loader
-- ---------------------------------------------------------------------------

local loader = require("src.core.template_loader")

local tmpl_list = loader.list()
check("template_loader: list returns a table", type(tmpl_list) == "table")
check("template_loader: includes hauler_loop",   tmpl_list[1] == "hauler_loop" or (function()
    for _, n in ipairs(tmpl_list) do if n == "hauler_loop" then return true end end
end)())
check("template_loader: includes miner_support", (function()
    for _, n in ipairs(tmpl_list) do if n == "miner_support" then return true end end
end)())
check("template_loader: includes patrol_route",  (function()
    for _, n in ipairs(tmpl_list) do if n == "patrol_route" then return true end end
end)())

-- load each template
for _, name in ipairs(tmpl_list) do
    local tmpl, err = loader.load(name)
    check("template_loader: load(" .. name .. ") succeeds", tmpl ~= nil, err)
end

-- ---------------------------------------------------------------------------
-- 2. Generator – hauler_loop (happy path)
-- ---------------------------------------------------------------------------

local hauler_result = generator.generate("hauler_loop", {
    pickup_register  = "A",
    dropoff_register = "B",
    item_filter      = "component_frame",
})

check("generator hauler_loop: returns table",        type(hauler_result) == "table")
check("generator hauler_loop: ok is true",           hauler_result.ok == true,
    table.concat((function() local m={} for _,w in ipairs(hauler_result.warnings or {}) do m[#m+1]=w.message end return m end)(), "; "))
check("generator hauler_loop: behavior has id",      type(hauler_result.behavior) == "table" and hauler_result.behavior.id ~= nil)
check("generator hauler_loop: source is string",     type(hauler_result.source) == "string")
check("generator hauler_loop: source has TODO",      hauler_result.source:find("TODO") ~= nil)
check("generator hauler_loop: pickup_register substituted",
    hauler_result.behavior.nodes ~= nil and
    hauler_result.behavior.nodes.move_to_pickup ~= nil and
    hauler_result.behavior.nodes.move_to_pickup.target_reg == "A")
check("generator hauler_loop: dropoff_register substituted",
    hauler_result.behavior.nodes.move_to_dropoff ~= nil and
    hauler_result.behavior.nodes.move_to_dropoff.target_reg == "B")

-- ---------------------------------------------------------------------------
-- 3. Generator – missing required parameter
-- ---------------------------------------------------------------------------

local missing_result = generator.generate("hauler_loop", {
    -- pickup_register intentionally omitted
    dropoff_register = "B",
})

check("generator hauler_loop missing param: ok is false", missing_result.ok == false)
local found_missing_error = false
for _, w in ipairs(missing_result.warnings) do
    if w.level == "error" and w.message:find("pickup_register") then
        found_missing_error = true
    end
end
check("generator hauler_loop missing param: error mentions pickup_register", found_missing_error)

-- ---------------------------------------------------------------------------
-- 4. Generator – unknown template
-- ---------------------------------------------------------------------------

local unknown_result = generator.generate("nonexistent_template", {})
check("generator unknown template: ok is false", unknown_result.ok == false)
check("generator unknown template: has error message",
    #unknown_result.warnings > 0 and unknown_result.warnings[1].level == "error")

-- ---------------------------------------------------------------------------
-- 5. Generator – miner_support (happy path)
-- ---------------------------------------------------------------------------

local miner_result = generator.generate("miner_support", {
    miner_register   = "C",
    storage_register = "D",
})
check("generator miner_support: ok", miner_result.ok == true,
    table.concat((function() local m={} for _,w in ipairs(miner_result.warnings or {}) do m[#m+1]=w.message end return m end)(), "; "))
check("generator miner_support: behavior id set", miner_result.behavior and miner_result.behavior.id ~= nil)

-- ---------------------------------------------------------------------------
-- 6. Generator – patrol_route (happy path)
-- ---------------------------------------------------------------------------

local patrol_result = generator.generate("patrol_route", {
    waypoint_registers = "A,B,C",
    pause_duration     = 3,
})
-- patrol_route uses {{waypoint_registers}} in multiple target_reg fields which
-- all get the same comma-string; that is by design (wizard expands them).
-- So the generator should succeed (no required params missing).
check("generator patrol_route: returns table", type(patrol_result) == "table")
check("generator patrol_route: behavior has id", patrol_result.behavior and patrol_result.behavior.id ~= nil)

-- ---------------------------------------------------------------------------
-- 7. Validator – unresolved placeholder
-- ---------------------------------------------------------------------------

local bad_behavior = {
    id         = "test_unresolved",
    name       = "Test",
    entry_node = "n1",
    nodes      = {
        n1 = { type = "move_to_entity", target_reg = "{{UNRESOLVED}}", next_node = "n1" },
    },
}
local bad_msgs = validator.validate(bad_behavior)
local found_unresolved = false
for _, m in ipairs(bad_msgs) do
    if m.level == "error" and m.message:find("UNRESOLVED") then
        found_unresolved = true
    end
end
check("validator: detects unresolved placeholder", found_unresolved)

-- ---------------------------------------------------------------------------
-- 8. Validator – invalid node reference
-- ---------------------------------------------------------------------------

local bad_ref = {
    id         = "test_bad_ref",
    name       = "Test",
    entry_node = "n1",
    nodes      = {
        n1 = { type = "wait", duration = 1, next_node = "MISSING_NODE" },
    },
}
local ref_msgs = validator.validate(bad_ref)
local found_ref_error = false
for _, m in ipairs(ref_msgs) do
    if m.level == "error" and m.message:find("MISSING_NODE") then
        found_ref_error = true
    end
end
check("validator: detects invalid node reference", found_ref_error)

-- ---------------------------------------------------------------------------
-- 9. Validator – missing required fields
-- ---------------------------------------------------------------------------

local no_id = { name = "NoId", nodes = {}, entry_node = nil }
local no_id_msgs = validator.validate(no_id)
local found_id_error = false
for _, m in ipairs(no_id_msgs) do
    if m.level == "error" and m.message:find("id") then found_id_error = true end
end
check("validator: error on missing 'id'", found_id_error)

local no_nodes = { id = "x", name = "X" }
local no_nodes_msgs = validator.validate(no_nodes)
local found_nodes_error = false
for _, m in ipairs(no_nodes_msgs) do
    if m.level == "error" and m.message:find("nodes") then found_nodes_error = true end
end
check("validator: error on missing 'nodes'", found_nodes_error)

-- ---------------------------------------------------------------------------
-- 10. Validator – custom rule registration
-- ---------------------------------------------------------------------------

local custom_fired = false
validator.add_rule(function(behavior, messages)
    if behavior.id == "trigger_custom_rule" then
        custom_fired = true
        messages[#messages + 1] = { level = "info", message = "custom rule fired" }
    end
end)
validator.validate({ id = "trigger_custom_rule", name = "T", nodes = {} })
check("validator: custom rule fires", custom_fired)

-- ---------------------------------------------------------------------------
-- Summary
-- ---------------------------------------------------------------------------

print(string.format("\nSelf-check complete. %d passed, %d failed.", passed, failed))

if failed > 0 then
    os.exit(1)
end
