# Template Format Reference

This document defines the schema for behavior template files used by
**Behavior The Easy Way**.

---

## Top-level table

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | **yes** | Unique snake_case identifier (e.g. `"hauler_loop"`). Must match the filename. |
| `version` | string | no | SemVer string (e.g. `"1.0.0"`). Used in generated source comments. |
| `description` | string | no | One-line description shown in the wizard UI. |
| `params` | ParamDef[] | no | Ordered list of parameter definitions (see below). |
| `behavior` | BehaviorDef | **yes** | The behavior graph definition with `{{PARAM}}` tokens. |

---

## ParamDef

Each entry in `params` is a table with:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | **yes** | Parameter key referenced as `{{name}}` in the behavior graph. Must be a valid Lua identifier (letters, digits, underscores). |
| `required` | boolean | no | If `true`, the generator returns an error when this param is absent. Default: `false`. |
| `default` | any | no | Value used when the param is not provided. Ignored if `required = true`. |
| `type` | string | no | Hint for the UI: `"string"`, `"number"`, `"register"`, `"boolean"`. No runtime enforcement – informational only. |
| `hint` | string | no | Tooltip / help text shown in the wizard dialog. |

---

## BehaviorDef

The `behavior` field is a table that will be registered with Desynced as a
behavior definition.  `{{PARAM}}` tokens in **string** values are replaced by
the generator before the table is used.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | **yes** | Unique behavior identifier. May contain `{{PARAM}}` tokens. |
| `name` | string | recommended | Human-readable display name. |
| `entry_node` | string | recommended | Node id where execution begins. |
| `nodes` | NodeMap | **yes** | Table mapping node id → NodeDef (see below). |

---

## NodeDef

Each value in `nodes` is a table describing one execution node.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | **yes** | Node type id as defined in Desynced's behavior node registry. |
| `next_node` | string | depends | Default successor node id. Required for linear nodes. |
| `on_true` | string | no | Successor when condition is true (for condition/branch nodes). |
| `on_false` | string | no | Successor when condition is false. |
| `on_success` | string | no | Successor on successful action. |
| `on_fail` | string | no | Successor on failed action. |
| *(other fields)* | any | no | Node-type-specific fields (e.g. `target_reg`, `duration`, `item_id`). May contain `{{PARAM}}` tokens. |

All node ids referenced in edge fields (`next_node`, `on_true`, etc.) must exist
as keys in the `nodes` table.  The validator enforces this.

---

## Placeholder token rules

- Tokens use the syntax `{{param_name}}` where `param_name` is a valid Lua
  identifier (alphanumeric + underscore, must start with a letter).
- Tokens are substituted in **string** values only; non-string fields are copied
  as-is.
- A token that has no corresponding parameter value is left intact and reported
  as an error by the validator.
- After substitution, if any `{{...}}` tokens remain in the final behavior, the
  validator raises an `"error"` level message.

---

## Example

```lua
return {
    id      = "example",
    version = "1.0.0",

    params = {
        { name = "target_reg", required = true,  type = "register" },
        { name = "wait_time",  required = false, default = 5, type = "number" },
    },

    behavior = {
        id         = "example_generated",
        name       = "Example",
        entry_node = "go",

        nodes = {
            go = {
                type       = "move_to_entity",
                target_reg = "{{target_reg}}",
                next_node  = "pause",
            },
            pause = {
                type      = "wait",
                duration  = "{{wait_time}}",
                next_node = "go",
            },
        },
    },
}
```
