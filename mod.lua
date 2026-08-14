-- mod.lua
-- Entry point for the "Behavior The Easy Way" Desynced mod.
-- Desynced calls this file when the mod is loaded.

local MOD_ID   = "BehaviorEasyWay"
local MOD_NAME = "Behavior The Easy Way"

-- Desynced exposes a global `dsmod` table; guard so the file also loads
-- in standalone Lua (for self-check / tests).
local dsmod = dsmod or {}

-- ---------------------------------------------------------------------------
-- Bootstrap helpers
-- ---------------------------------------------------------------------------

--- Resolve a module path relative to this mod's root.
--- In-game Desynced uses its own require path; outside we fall back to the
--- standard loader so tests can run with plain `lua`.
local function mod_require(path)
    return require(path)
end

-- ---------------------------------------------------------------------------
-- Load sub-systems
-- ---------------------------------------------------------------------------

local ok, generator = pcall(mod_require, "src.core.generator")
if not ok then
    -- In-game paths use dot-separated mod namespace.
    generator = mod_require(MOD_ID .. ".src.core.generator")
end

local ok2, wizard = pcall(mod_require, "src.ui.wizard")
if not ok2 then
    wizard = mod_require(MOD_ID .. ".src.ui.wizard")
end

-- ---------------------------------------------------------------------------
-- Register with Desynced (no-op when running standalone)
-- ---------------------------------------------------------------------------

if dsmod.register then
    dsmod.register(MOD_ID, {
        name        = MOD_NAME,
        version     = "0.1.0",
        description = "Template-driven behavior scaffold generator with built-in validator.",
        on_load     = function()
            wizard.init(generator)
        end,
    })
end

-- ---------------------------------------------------------------------------
-- Public API (usable from Lua console or other mods)
-- ---------------------------------------------------------------------------

return {
    generate = function(template_name, params)
        return generator.generate(template_name, params)
    end,
    list_templates = function()
        return generator.list_templates()
    end,
}
