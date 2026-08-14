-- src/ui/wizard.lua
-- In-game wizard dialog for the "Behavior The Easy Way" mod.
--
-- This module registers a toolbar button on the Behavior Controller panel.
-- When clicked it opens a guided dialog that:
--   1. Shows a list of available templates
--   2. Accepts parameter values
--   3. Calls generator.generate() and registers the behavior in-game
--
-- The Desynced UI API is used where available; the module degrades gracefully
-- when running outside the game (e.g. in self_check.lua).

local Wizard = {}

-- Guard: only use UI APIs when inside the game
local HAS_UI = (dsui ~= nil) or false

-- Held reference to the generator (injected via Wizard.init)
local _generator = nil

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Show a simple message in the game UI or fall back to print().
local function notify(msg)
    if HAS_UI and dsui.notify then
        dsui.notify(msg)
    else
        print("[BehaviorEasyWay] " .. tostring(msg))
    end
end

--- Collect messages of a given level from a warnings list.
local function filter_messages(warnings, level)
    local out = {}
    for _, w in ipairs(warnings) do
        if w.level == level then out[#out + 1] = w.message end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- Dialog builder (simplified – real implementation hooks dsui.open_dialog)
-- ---------------------------------------------------------------------------

local function build_param_fields(template_def)
    local fields = {}
    if type(template_def.params) ~= "table" then return fields end
    for _, pd in ipairs(template_def.params) do
        fields[#fields + 1] = {
            key      = pd.name,
            label    = pd.name .. (pd.required and " *" or ""),
            hint     = pd.hint or "",
            default  = pd.default or "",
        }
    end
    return fields
end

--- Open the wizard dialog.
--- `on_submit` is called with the collected param table.
local function open_wizard_dialog(template_names, on_template_select)
    if not HAS_UI then
        -- Headless fallback: just list templates
        print("[BehaviorEasyWay] Available templates:")
        for _, name in ipairs(template_names) do
            print("  - " .. name)
        end
        print("[BehaviorEasyWay] Use generator.generate(name, params) to create a behavior.")
        return
    end

    -- TODO: replace stub with real dsui.open_dialog implementation
    --       once the full Desynced UI API is mapped.
    dsui.open_dialog({
        title  = "Behavior The Easy Way – Choose Template",
        fields = {
            {
                key    = "template",
                label  = "Template",
                type   = "select",
                options = template_names,
            },
        },
        on_submit = function(values)
            on_template_select(values.template)
        end,
    })
end

local function open_param_dialog(template_def, on_submit)
    if not HAS_UI then return end

    local fields = build_param_fields(template_def)

    -- TODO: replace stub with real dsui.open_dialog call
    dsui.open_dialog({
        title  = "Parameters for: " .. (template_def.id or "template"),
        fields = fields,
        on_submit = on_submit,
    })
end

-- ---------------------------------------------------------------------------
-- Wizard flow
-- ---------------------------------------------------------------------------

local function run_wizard()
    if not _generator then
        notify("ERROR: generator not initialized.")
        return
    end

    local template_names = _generator.list_templates()

    open_wizard_dialog(template_names, function(selected_name)
        -- Load template to get its param spec
        local loader = require("src.core.template_loader")
        local tmpl   = loader.load(selected_name)
        if not tmpl then
            notify("Failed to load template: " .. selected_name)
            return
        end

        open_param_dialog(tmpl, function(params)
            local result = _generator.generate(selected_name, params)

            if not result.ok then
                local errors = filter_messages(result.warnings, "error")
                notify("Generation failed:\n" .. table.concat(errors, "\n"))
                return
            end

            local warnings = filter_messages(result.warnings, "warning")
            if #warnings > 0 then
                notify("Generated with warnings:\n" .. table.concat(warnings, "\n"))
            end

            -- TODO: register the behavior in the game world
            -- dsmod.register_behavior(result.behavior)

            notify("Behavior '" .. (result.behavior.id or "?") .. "' generated successfully.")
        end)
    end)
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Initialize the wizard and register the toolbar button in-game.
---@param generator table  The generator module returned by src.core.generator
function Wizard.init(generator)
    _generator = generator

    if HAS_UI and dsui.add_toolbar_button then
        dsui.add_toolbar_button({
            id      = "easy_behavior_wizard",
            label   = "Easy Behavior",
            tooltip = "Generate a behavior from a template",
            panel   = "behavior_controller",
            on_click = run_wizard,
        })
    end
end

--- Expose run_wizard for testing / console use.
Wizard.run = run_wizard

return Wizard
