-- src/templates/miner_support.lua
-- Template: Miner Support
--
-- Generates a behavior for a support bot that monitors a mining unit,
-- collects its output, and ferries it to a storage entity.
--
-- Required parameters:
--   miner_register   – register holding the mining unit entity
--   storage_register – register holding the storage entity
--
-- Optional parameters:
--   check_interval  – seconds between inventory checks (default: 10)
--   behavior_id
--   behavior_name

return {
    id          = "miner_support",
    version     = "1.0.0",
    description = "Support bot that empties a miner's inventory and transfers items to storage.",

    params = {
        {
            name     = "miner_register",
            required = true,
            type     = "register",
            hint     = "Register holding the mining unit to service.",
        },
        {
            name     = "storage_register",
            required = true,
            type     = "register",
            hint     = "Register holding the target storage entity.",
        },
        {
            name     = "check_interval",
            required = false,
            default  = 10,
            type     = "number",
            hint     = "Seconds to wait between miner inventory checks.",
        },
        {
            name    = "behavior_id",
            required = false,
            default  = "miner_support_generated",
            type    = "string",
            hint    = "Unique id for the generated behavior.",
        },
        {
            name    = "behavior_name",
            required = false,
            default  = "Miner Support (generated)",
            type    = "string",
            hint    = "Human-readable name shown in-game.",
        },
    },

    behavior = {
        id         = "{{behavior_id}}",
        name       = "{{behavior_name}}",
        entry_node = "move_to_miner",

        nodes = {
            -- Step 1: go to the miner
            move_to_miner = {
                type       = "move_to_entity",
                target_reg = "{{miner_register}}",
                next_node  = "check_miner_inventory",
                arrival_distance = 1,
            },

            -- Step 2: check if miner has items to collect
            check_miner_inventory = {
                type       = "check_inventory",
                target_reg = "{{miner_register}}",
                on_true    = "collect_from_miner",    -- miner has items
                on_false   = "wait_for_miner",        -- miner is empty
            },

            -- Step 2b: miner has nothing – wait and re-check
            wait_for_miner = {
                type      = "wait",
                duration  = "{{check_interval}}",
                -- TODO: consider using an event trigger instead of polling
                next_node = "check_miner_inventory",
            },

            -- Step 3: collect items from miner
            collect_from_miner = {
                type       = "transfer_items",
                source_reg = "{{miner_register}}",
                on_success = "move_to_storage",
                on_fail    = "wait_for_miner",
            },

            -- Step 4: go to storage
            move_to_storage = {
                type       = "move_to_entity",
                target_reg = "{{storage_register}}",
                next_node  = "deposit_to_storage",
                arrival_distance = 1,
            },

            -- Step 5: deposit at storage
            deposit_to_storage = {
                type       = "deposit_items",
                target_reg = "{{storage_register}}",
                on_success = "move_to_miner",   -- loop
                on_fail    = "wait_storage_full",
            },

            -- Step 5b: storage full
            wait_storage_full = {
                type      = "wait",
                -- TODO: tune or replace with event-based logic
                duration  = 30,
                next_node = "move_to_storage",
            },
        },
    },
}
