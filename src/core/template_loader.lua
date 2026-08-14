-- src/core/template_loader.lua
-- Discovers and loads behavior template definitions.
--
-- Templates are Lua modules under src/templates/ that return a table
-- conforming to the schema described in docs/TEMPLATE_FORMAT.md.
-- The loader resolves them by name (filename without .lua extension).

local TemplateLoader = {}

-- Hard-coded list of bundled templates.
-- When new templates are added to src/templates/ they must also be listed here
-- (Desynced's sandbox does not allow dynamic filesystem scanning).
local BUNDLED_TEMPLATES = {
    "hauler_loop",
    "miner_support",
    "patrol_route",
}

local _cache = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Try several require strategies so the module works both in-game and
--- in a plain Lua interpreter used for tests.
local function try_require(name)
    local strategies = {
        "src.templates." .. name,
        "BehaviorEasyWay.src.templates." .. name,
        "templates." .. name,
    }
    for _, path in ipairs(strategies) do
        local ok, result = pcall(require, path)
        if ok and type(result) == "table" then
            return result
        end
    end
    return nil, "Could not load template '" .. name .. "'"
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Return a list of all known template names.
function TemplateLoader.list()
    local names = {}
    for _, name in ipairs(BUNDLED_TEMPLATES) do
        names[#names + 1] = name
    end
    return names
end

--- Load and return a template by name.
--- Returns the template table, or nil + error message on failure.
---@param name string  Template identifier (e.g. "hauler_loop")
---@return table|nil template
---@return string|nil error_message
function TemplateLoader.load(name)
    if _cache[name] then
        return _cache[name]
    end

    local tmpl, err = try_require(name)
    if not tmpl then
        return nil, err
    end

    _cache[name] = tmpl
    return tmpl
end

--- Reload all templates (clears cache).  Useful during development.
function TemplateLoader.reload()
    _cache = {}
end

return TemplateLoader
