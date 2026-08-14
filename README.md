# Desynced – Behavior The Easy Way

A **Desynced mod** that makes authoring and reusing behavior programs dramatically easier.
Instead of building every behavior graph from scratch inside the game's editor, this mod provides:

- **Parameterized templates** for common bot jobs (hauler, miner-support, patrol…)
- A **scaffold generator** that fills in placeholders and marks manual-completion spots with `TODO`
- A **validator / linter** that catches common mistakes before you save
- An **in-game UI entry point** that walks you through template selection and parameter entry

---

## Quick-start

### 1. Install the mod
Place (or symlink) this folder inside your Desynced mods directory, e.g.:

```
%APPDATA%\Desynced\mods\BehaviorEasyWay\
```

### 2. Activate in-game
Open the **Mod Manager** in Desynced and enable *"Behavior The Easy Way"*.

### 3. Generate a behavior scaffold

#### In-game UI
Click the **"Easy Behavior"** button that appears in the Behavior Controller toolbar.  
A dialog will open – choose a template, fill in parameters, and press **Generate**.

#### Lua console / script
```lua
local gen = require("BehaviorEasyWay.core.generator")

local result = gen.generate("hauler_loop", {
    pickup_register  = "A",
    dropoff_register = "B",
    item_filter      = "component_frame",
})

-- result.behavior  – the behavior definition table ready to register
-- result.warnings  – list of validator messages
-- result.source    – annotated Lua source with TODO markers
```

### 4. Validate an existing behavior table
```lua
local validator = require("BehaviorEasyWay.validators.behavior_validator")

local messages = validator.validate(my_behavior_table)
for _, msg in ipairs(messages) do
    print(msg.level .. ": " .. msg.message)
end
```

---

## Project layout

```
BehaviorEasyWay/
├── mod.lua                  – Mod entry point (registers with Desynced)
├── src/
│   ├── core/
│   │   ├── generator.lua    – Scaffold generator: loads template, substitutes params
│   │   └── template_loader.lua – Discovers and loads template files
│   ├── templates/
│   │   ├── hauler_loop.lua      – Hauler pickup/dropoff loop template
│   │   ├── miner_support.lua    – Miner-support bot template
│   │   └── patrol_route.lua     – Simple patrol / waypoint route template
│   ├── validators/
│   │   └── behavior_validator.lua – Linting rules for behavior tables
│   └── ui/
│       └── wizard.lua           – In-game wizard / scaffold dialog
├── docs/
│   ├── EXTENSION_GUIDE.md   – How to add new templates and validators
│   └── TEMPLATE_FORMAT.md   – Template table schema reference
└── tests/
    └── self_check.lua       – Standalone validation / self-test script
```

---

## How to add a new template

See [`docs/EXTENSION_GUIDE.md`](docs/EXTENSION_GUIDE.md) for the full walkthrough.  
Short version:

1. Create `src/templates/my_template.lua` that returns a table conforming to the
   schema in [`docs/TEMPLATE_FORMAT.md`](docs/TEMPLATE_FORMAT.md).
2. The template loader discovers it automatically by scanning the `templates/` folder.
3. Run `tests/self_check.lua` to verify your template passes built-in validation.

---

## Running the self-check

Outside the game (requires a standalone Lua 5.4 interpreter):

```bash
lua tests/self_check.lua
```

Expected output when everything is healthy:
```
[PASS] hauler_loop        – 0 errors, 0 warnings
[PASS] miner_support      – 0 errors, 0 warnings
[PASS] patrol_route       – 0 errors, 0 warnings
Self-check complete. All templates OK.
```

---

## Contributing

Pull requests are welcome.  See [`docs/EXTENSION_GUIDE.md`](docs/EXTENSION_GUIDE.md).

## License

MIT