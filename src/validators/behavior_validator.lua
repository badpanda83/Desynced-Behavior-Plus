-- src/validators/behavior_validator.lua
-- Linting / validation rules for a Desynced behavior definition table.
--
-- Usage:
--   local validator = require("src.validators.behavior_validator")
--   local messages  = validator.validate(behavior_table)
--   -- messages is a list of { level = "error"|"warning"|"info", message = string }

local Validator = {}

local PLACEHOLDER_PATTERN = "{{([%w_]+)}}"

-- ---------------------------------------------------------------------------
-- Internal rule helpers
-- ---------------------------------------------------------------------------

--- Collect all string values in a (possibly nested) table.
local function collect_strings(tbl, out)
    out = out or {}
    if type(tbl) ~= "table" then return out end
    for _, v in pairs(tbl) do
        if type(v) == "string" then
            out[#out + 1] = v
        elseif type(v) == "table" then
            collect_strings(v, out)
        end
    end
    return out
end

--- Collect all node ids referenced inside the behavior graph.
--- Returns a set of ids that are defined, and a list of references.
local function collect_node_refs(nodes)
    local defined = {}
    local refs    = {}  -- {from_id, to_id}
    if type(nodes) ~= "table" then return defined, refs end
    for id, node in pairs(nodes) do
        defined[id] = true
        if type(node) == "table" then
            -- next_node or on_true / on_false / next are common edge fields
            for _, edge_key in ipairs({ "next_node", "next", "on_true", "on_false", "on_success", "on_fail" }) do
                if node[edge_key] ~= nil then
                    refs[#refs + 1] = { from = id, to = node[edge_key] }
                end
            end
        end
    end
    return defined, refs
end

-- ---------------------------------------------------------------------------
-- Rule implementations
-- ---------------------------------------------------------------------------

--- Rule: behavior must have an id field.
local function rule_has_id(behavior, messages)
    if behavior.id == nil or behavior.id == "" then
        messages[#messages + 1] = {
            level   = "error",
            message = "Behavior is missing required field 'id'.",
        }
    end
end

--- Rule: behavior must have a nodes table (even if empty).
local function rule_has_nodes(behavior, messages)
    if type(behavior.nodes) ~= "table" then
        messages[#messages + 1] = {
            level   = "error",
            message = "Behavior is missing 'nodes' table.",
        }
    end
end

--- Rule: behavior should have a human-readable name.
local function rule_has_name(behavior, messages)
    if behavior.name == nil or behavior.name == "" then
        messages[#messages + 1] = {
            level   = "warning",
            message = "Behavior is missing 'name' field (recommended for UI display).",
        }
    end
end

--- Rule: no unresolved {{PLACEHOLDER}} tokens remain.
local function rule_no_unresolved_placeholders(behavior, messages)
    local strings = collect_strings(behavior)
    local seen    = {}
    for _, s in ipairs(strings) do
        for token in s:gmatch(PLACEHOLDER_PATTERN) do
            if not seen[token] then
                seen[token] = true
                messages[#messages + 1] = {
                    level   = "error",
                    message = "Unresolved placeholder token: {{" .. token .. "}}",
                }
            end
        end
    end
end

--- Rule: all node edge references must point to defined nodes.
local function rule_valid_node_refs(behavior, messages)
    if type(behavior.nodes) ~= "table" then return end
    local defined, refs = collect_node_refs(behavior.nodes)
    for _, ref in ipairs(refs) do
        if not defined[ref.to] then
            messages[#messages + 1] = {
                level   = "error",
                message = string.format(
                    "Node '%s' references undefined node '%s'.",
                    tostring(ref.from), tostring(ref.to)
                ),
            }
        end
    end
end

--- Rule: nodes must each have a 'type' field.
local function rule_nodes_have_type(behavior, messages)
    if type(behavior.nodes) ~= "table" then return end
    for id, node in pairs(behavior.nodes) do
        if type(node) == "table" and (node.type == nil or node.type == "") then
            messages[#messages + 1] = {
                level   = "error",
                message = string.format("Node '%s' is missing required 'type' field.", tostring(id)),
            }
        end
    end
end

--- Rule: behavior should define an entry_node.
local function rule_has_entry_node(behavior, messages)
    if type(behavior.nodes) ~= "table" then return end
    if behavior.entry_node == nil then
        messages[#messages + 1] = {
            level   = "warning",
            message = "Behavior does not define 'entry_node'; the first execution step is ambiguous.",
        }
    elseif behavior.nodes[behavior.entry_node] == nil then
        messages[#messages + 1] = {
            level   = "error",
            message = string.format(
                "entry_node '%s' does not exist in 'nodes'.", tostring(behavior.entry_node)
            ),
        }
    end
end

-- ---------------------------------------------------------------------------
-- Rule registry
-- ---------------------------------------------------------------------------

local RULES = {
    rule_has_id,
    rule_has_nodes,
    rule_has_name,
    rule_no_unresolved_placeholders,
    rule_valid_node_refs,
    rule_nodes_have_type,
    rule_has_entry_node,
}

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Validate a behavior definition table and return a list of messages.
---@param behavior table  The behavior table to validate.
---@return table messages  List of { level = string, message = string }
function Validator.validate(behavior)
    local messages = {}
    if type(behavior) ~= "table" then
        return { { level = "error", message = "validate() expects a table, got " .. type(behavior) } }
    end
    for _, rule in ipairs(RULES) do
        rule(behavior, messages)
    end
    return messages
end

--- Register a custom validation rule function.
--- The function receives (behavior, messages) and appends to messages.
---@param rule_fn function
function Validator.add_rule(rule_fn)
    if type(rule_fn) == "function" then
        RULES[#RULES + 1] = rule_fn
    end
end

return Validator
