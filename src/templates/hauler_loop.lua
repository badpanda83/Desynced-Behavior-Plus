-- src/templates/hauler_loop.lua
-- Template: Hauler Loop
--
-- Generates a continuous pickup → move-to-dropoff → deposit loop behavior
-- suitable for bots transporting resources between two locations.
--
-- Required parameters:
--   pickup_register   – register letter (e.g. "A") holding the pickup target
--   dropoff_register  – register letter (e.g. "B") holding the dropoff target
--
-- Optional parameters:
--   item_filter  – item id to restrict pickup (default: any)
--   behavior_id  – override the generated behavior id
--   behavior_name – override the display name

return {
    -- Template metadata
    id          = "hauler_loop",
    version     = "1.0.0",
    description = "Continuous hauler: pick up items from one location, deliver to another, repeat.",

    -- Parameter definitions
    params = {
        {
            name     = "pickup_register",
            required = true,
            type     = "register",
            hint     = "Register containing the pickup-point entity (e.g. 'A').",
        },
        {
            name     = "dropoff_register",
            required = true,
            type     = "register",
            hint     = "Register containing the drop-off entity (e.g. 'B').",
        },
        {
            name    = "item_filter",
            required = false,
            default  = "",
            type     = "string",
            hint     = "Optional item id to restrict pickup (leave blank for any item).",
        },
        {
            name    = "behavior_id",
            required = false,
            default  = "hauler_loop_generated",
            type     = "string",
            hint     = "Unique id for the generated behavior.",
        },
        {
            name    = "behavior_name",
            required = false,
            default  = "Hauler Loop (generated)",
            type     = "string",
            hint     = "Human-readable name shown in-game.",
        },
    },

    -- Behavior graph (uses {{PARAM}} tokens substituted by the generator)
    behavior = {
        id          = "{{behavior_id}}",
        name        = "{{behavior_name}}",
        entry_node  = "move_to_pickup",

        nodes = {
            -- Step 1: move to the pickup entity stored in the pickup register
            move_to_pickup = {
                type       = "move_to_entity",
                target_reg = "{{pickup_register}}",
                next_node  = "pick_up",
                -- TODO: adjust arrival_distance if needed
                arrival_distance = 1,
            },

            -- Step 2: pick up items (optionally filtered)
            pick_up = {
                type      = "pick_up_items",
                source_reg = "{{pickup_register}}",
                item_id   = "{{item_filter}}",  -- empty string means "any"
                on_success = "move_to_dropoff",
                on_fail    = "wait_at_pickup",
            },

            -- Step 2b: nothing to pick up yet – wait and retry
            wait_at_pickup = {
                type      = "wait",
                -- TODO: tune wait duration (seconds) or switch to event-based wait
                duration  = 5,
                next_node = "move_to_pickup",
            },

            -- Step 3: carry items to dropoff
            move_to_dropoff = {
                type       = "move_to_entity",
                target_reg = "{{dropoff_register}}",
                next_node  = "deposit",
                arrival_distance = 1,
            },

            -- Step 4: deposit items
            deposit = {
                type       = "deposit_items",
                target_reg = "{{dropoff_register}}",
                on_success = "move_to_pickup",  -- loop back
                on_fail    = "wait_at_dropoff",
            },

            -- Step 4b: dropoff full – wait and retry
            wait_at_dropoff = {
                type      = "wait",
                -- TODO: tune wait duration
                duration  = 5,
                next_node = "move_to_dropoff",
            },
        },
    },
}
