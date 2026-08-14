-- src/templates/patrol_route.lua
-- Template: Patrol / Waypoint Route
--
-- Generates a behavior for a bot that visits a sequence of waypoints
-- in order, then loops back to the first one.
--
-- Required parameters:
--   waypoint_registers – comma-separated register letters for waypoints
--                        (e.g. "A,B,C").  At least one required.
--
-- Optional parameters:
--   pause_duration  – seconds to pause at each waypoint (default: 2)
--   behavior_id
--   behavior_name

return {
    id          = "patrol_route",
    version     = "1.0.0",
    description = "Bot patrols a sequence of waypoints in order, looping indefinitely.",

    params = {
        {
            name     = "waypoint_registers",
            required = true,
            type     = "string",
            hint     = "Comma-separated register letters for each waypoint, e.g. 'A,B,C'.",
        },
        {
            name     = "pause_duration",
            required = false,
            default  = 2,
            type     = "number",
            hint     = "Seconds to pause at each waypoint before moving on.",
        },
        {
            name    = "behavior_id",
            required = false,
            default  = "patrol_route_generated",
            type    = "string",
            hint    = "Unique id for the generated behavior.",
        },
        {
            name    = "behavior_name",
            required = false,
            default  = "Patrol Route (generated)",
            type    = "string",
            hint    = "Human-readable name shown in-game.",
        },
    },

    -- Note: because the number of waypoints is dynamic, the generator
    -- produces a fixed 3-waypoint skeleton.  The in-game wizard expands
    -- this into the correct number of nodes based on waypoint_registers.
    -- For a direct Lua call with > 3 waypoints, add nodes manually or
    -- call Generator.generate_patrol(params) for the dynamic version.
    behavior = {
        id         = "{{behavior_id}}",
        name       = "{{behavior_name}}",
        entry_node = "move_to_wp1",

        nodes = {
            -- Waypoint 1
            move_to_wp1 = {
                type       = "move_to_entity",
                -- TODO: replace with the first register from waypoint_registers
                target_reg = "{{waypoint_registers}}",
                next_node  = "pause_wp1",
                arrival_distance = 0,
            },
            pause_wp1 = {
                type      = "wait",
                duration  = "{{pause_duration}}",
                next_node = "move_to_wp2",
            },

            -- Waypoint 2
            -- TODO: add/remove waypoint blocks to match waypoint_registers count
            move_to_wp2 = {
                type       = "move_to_entity",
                target_reg = "{{waypoint_registers}}",
                next_node  = "pause_wp2",
                arrival_distance = 0,
            },
            pause_wp2 = {
                type      = "wait",
                duration  = "{{pause_duration}}",
                next_node = "move_to_wp3",
            },

            -- Waypoint 3
            move_to_wp3 = {
                type       = "move_to_entity",
                target_reg = "{{waypoint_registers}}",
                next_node  = "pause_wp3",
                arrival_distance = 0,
            },
            pause_wp3 = {
                type      = "wait",
                duration  = "{{pause_duration}}",
                next_node = "move_to_wp1",  -- loop back
            },
        },
    },
}
