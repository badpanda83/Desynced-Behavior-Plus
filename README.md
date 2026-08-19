# Desynced-Behavior-Plus

A mod scaffold for adding custom behaviors to Desynced.

## Current behavior set

- **Attack Unit** – orders a unit to attack a target unit.
- **Spawn Test Encounter** – spawns a hostile wave on demand for validating automated defenses.

## Project structure

- `README.md` – project documentation
- `mod/behaviors/attack_unit.lua` – Attack Unit behavior script
- `mod/behaviors/spawn_encounter.lua` – Spawn Test Encounter behavior script
- `mod/behaviors/init.lua` – behavior registration entry point
- `mod/mod_info.lua` – mod metadata
- `tests/test_spawn_encounter.lua` – lightweight test suite for `spawn_encounter`

## Spawn Test Encounter

### Purpose

Trigger a hostile encounter on demand so you can validate automated defenses
without waiting for a natural in-game wave.

### Inputs

| Key | Type | Required | Default | Description |
|---|---|---|---|---|
| `spawn_point` | position `{x, y}` | ✔ | – | World position to spawn hostiles at |
| `species` | string | – | `"alien"` | `"alien"` or `"bug_swarm"` |
| `difficulty` | number | – | `1` | Integer 1–5 (see table below) |

### Difficulty scale

| Level | Unit count | Tier | Health multiplier |
|---|---|---|---|
| 1 (easy) | 2 | 1 | ×1.0 |
| 2 | 4 | 1 | ×1.5 |
| 3 | 6 | 2 | ×2.0 |
| 4 | 8 | 2 | ×3.0 |
| 5 (nightmare) | 12 | 3 | ×4.0 |

Values outside 1–5 are clamped automatically.

### Usage example

```lua
local ctx = {
  spawn_point = { x = 100, y = 200 },
  species     = "bug_swarm",   -- or "alien"
  difficulty  = 3,
  command = {
    spawn_hostile = function(species, pos, opts)
      -- delegate to your runtime's actual spawn API
    end,
  },
}

local SpawnEncounter = require("mod.behaviors.spawn_encounter")
local ok, err = SpawnEncounter.execute(ctx)
```

### Running the tests

```bash
lua5.4 tests/test_spawn_encounter.lua
```

## Notes

You can add additional behaviors in `mod/behaviors/` and register them in
`mod/behaviors/init.lua`. Follow the same `validate` / `execute` pattern used
by `attack_unit` and `spawn_encounter`.

