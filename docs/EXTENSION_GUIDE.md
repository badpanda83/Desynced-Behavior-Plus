# Extension Guide – Adding New Templates and Validators

This guide explains how to extend the **Behavior The Easy Way** mod with:

- New behavior templates
- New validation rules

---

## 1. Adding a new template

### 1.1 Create the template file

Create a new Lua file under `src/templates/`:

```
src/templates/my_new_template.lua
```

The file must return a table conforming to the [Template Format](TEMPLATE_FORMAT.md):

```lua
return {
    id          = "my_new_template",      -- unique snake_case identifier
    version     = "1.0.0",
    description = "One-line description shown in the wizard UI.",

    params = {
        {
            name     = "my_param",
            required = true,
            type     = "string",
            hint     = "Describe what this value controls.",
        },
        {
            name     = "optional_param",
            required = false,
            default  = "some_default",
            type     = "string",
            hint     = "Optional; defaults to 'some_default'.",
        },
    },

    behavior = {
        id         = "{{my_param}}_behavior",
        name       = "My Template (generated)",
        entry_node = "first_step",

        nodes = {
            first_step = {
                type      = "some_action",
                some_field = "{{optional_param}}",
                next_node  = "first_step",    -- loop, or point to next node
            },
        },
    },
}
```

### 1.2 Register the template name

Open `src/core/template_loader.lua` and add your template's id to the
`BUNDLED_TEMPLATES` list:

```lua
local BUNDLED_TEMPLATES = {
    "hauler_loop",
    "miner_support",
    "patrol_route",
    "my_new_template",   -- <-- add here
}
```

This is required because Desynced's sandbox does not permit dynamic filesystem
scanning at runtime.

### 1.3 Verify with the self-check

```bash
lua tests/self_check.lua
```

You should see a new `[PASS]` line for `template_loader: load(my_new_template)`.

If you want a full generation test, add a test block in `tests/self_check.lua`
following the pattern of the existing `hauler_loop` tests.

---

## 2. Adding a new validation rule

### 2.1 Option A – register at runtime (simplest)

Call `Validator.add_rule()` with any function that accepts `(behavior, messages)`:

```lua
local validator = require("src.validators.behavior_validator")

validator.add_rule(function(behavior, messages)
    if behavior.max_retries ~= nil and behavior.max_retries < 1 then
        messages[#messages + 1] = {
            level   = "error",
            message = "max_retries must be >= 1.",
        }
    end
end)
```

This works from `mod.lua`, another template, or the Lua console.

### 2.2 Option B – add a rule to behavior_validator.lua (persistent)

Open `src/validators/behavior_validator.lua` and:

1. Write a local function following the naming convention `rule_<description>`:

```lua
local function rule_custom_check(behavior, messages)
    -- Your logic here
    if not behavior.author then
        messages[#messages + 1] = {
            level   = "warning",
            message = "Behavior is missing 'author' metadata.",
        }
    end
end
```

2. Add it to the `RULES` table at the bottom of the file:

```lua
local RULES = {
    -- ... existing rules ...
    rule_custom_check,  -- <-- add here
}
```

### 2.3 Test your rule

Add a test case in `tests/self_check.lua`:

```lua
local test_behavior = { id = "x", name = "X", nodes = {} }
local msgs = validator.validate(test_behavior)
local found = false
for _, m in ipairs(msgs) do
    if m.level == "warning" and m.message:find("author") then found = true end
end
check("validator: warns on missing author", found)
```

Run `lua tests/self_check.lua` to confirm.

---

## 3. Template design tips

| Tip | Detail |
|-----|--------|
| **Use `{{PARAM}}` tokens freely** | Any `{{token}}` in a string value is substituted by the generator. Unresolved tokens produce validator errors. |
| **Mark manual steps** | Leave `-- TODO:` comments in your template near any node where the user is expected to fill in game-specific logic. These appear verbatim in the generated source. |
| **Default values** | Provide sensible defaults for optional parameters so templates work as demos without needing all params. |
| **Node ids** | Use descriptive snake_case ids like `move_to_pickup`; they appear in-game and in error messages. |
| **Edge keys** | Use standard edge key names (`next_node`, `on_true`, `on_false`, `on_success`, `on_fail`) so the validator can check cross-references. |

---

## 4. File checklist for a new template

- [ ] `src/templates/<name>.lua` – template file created
- [ ] `src/core/template_loader.lua` – name added to `BUNDLED_TEMPLATES`
- [ ] `tests/self_check.lua` – generation test added (recommended)
- [ ] Self-check passes: `lua tests/self_check.lua`
