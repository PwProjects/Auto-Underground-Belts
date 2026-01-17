local underground_tiles = {}
local underground_cache = {}

--------------------------------------------------
-- Initialization
--------------------------------------------------

local function update_caches()
    underground_tiles = {}
    local s = settings.global

    -- Map setting names converted to internal tile names
    local mapping = {
        ["aub-use-stone-path"] = "stone-path",
        ["aub-use-concrete"] = "concrete",
        ["aub-use-refined-concrete"] = "refined-concrete",
        ["aub-use-hazard-concrete-left"] = "hazard-concrete-left",
        ["aub-use-hazard-concrete-right"] = "hazard-concrete-right",
        ["aub-use-refined-hazard-concrete-left"] = "refined-hazard-concrete-left",
        ["aub-use-refined-hazard-concrete-right"] = "refined-hazard-concrete-right"
    }

    for setting_name, tile_name in pairs(mapping) do
        if s[setting_name] and s[setting_name].value then
            underground_tiles[tile_name] = true
        end
    end

    -- Prototype Cache
    underground_cache = {}
    for name, proto in pairs(prototypes.entity) do
        if proto.type == "underground-belt" then
            if not underground_cache[proto.belt_speed] then
                underground_cache[proto.belt_speed] = name
            end
        end
    end
end

--------------------------------------------------
-- Logic
--------------------------------------------------

local function get_direction_vector(dir)
    local vectors = {
        [defines.direction.north] = {
            x = 0,
            y = -1
        },
        [defines.direction.south] = {
            x = 0,
            y = 1
        },
        [defines.direction.east] = {
            x = 1,
            y = 0
        },
        [defines.direction.west] = {
            x = -1,
            y = 0
        }
    }
    return vectors[dir] or {
        x = 0,
        y = 0
    }
end

local function process_belt(belt)
    if not (belt and belt.valid) then
        return
    end

    -- Trigger: Only start the logic if the belt we just placed is on a non-concrete tile
    local current_tile = belt.surface.get_tile(belt.position).name
    if underground_tiles[current_tile] then
        return
    end

    local ug_name = underground_cache[belt.prototype.belt_speed]
    if not ug_name then
        return
    end

    local dir = belt.direction
    local vec = get_direction_vector(dir)
    local max_dist = prototypes.entity[ug_name].max_underground_distance or 5

    -- Look backwards from the current belt to find a chain of concrete belts and eventually the starting anchor.
    local concrete_chain = {}
    local start_anchor = nil
    local back_vec = {
        x = -vec.x,
        y = -vec.y
    }

    local check_pos = {
        x = belt.position.x,
        y = belt.position.y
    }

    while true do
        check_pos.x = check_pos.x + back_vec.x
        check_pos.y = check_pos.y + back_vec.y

        local found = belt.surface.find_entities_filtered({
            position = check_pos,
            type = "transport-belt",
            force = belt.force
        })[1]

        if not found or found.direction ~= dir then
            break
        end

        local t_name = found.surface.get_tile(found.position).name
        if underground_tiles[t_name] then
            -- The belt hit some concrete.
            table.insert(concrete_chain, found)
        else
            -- The belt hit something on the other side of the concrete.
            start_anchor = found
            break
        end

        -- Safety break if concrete is longer than underground reach of the belt type.
        if #concrete_chain > max_dist then
            break
        end
    end

    -- Execution: Only if we have a valid start (non-concrete), middle (concrete) and end (non-concrete).
    if start_anchor and #concrete_chain > 0 then
        local surface = belt.surface
        local force = belt.force
        local qual = belt.quality

        local p1 = start_anchor.position
        local p2 = belt.position -- This is the belt we just placed

        -- Destroy the anchor belts and all belts on the concrete
        start_anchor.destroy()
        belt.destroy()
        for _, b in ipairs(concrete_chain) do
            if b.valid then
                b.destroy()
            end
        end

        -- Create the underground jump
        surface.create_entity({
            name = ug_name,
            position = p1,
            direction = dir,
            force = force,
            type = "input",
            quality = qual
        })
        surface.create_entity({
            name = ug_name,
            position = p2,
            direction = dir,
            force = force,
            type = "output",
            quality = qual
        })

        -- Play sound effect
        surface.play_sound({
            path = "utility/build_medium",
            position = p2,
            volume_multiplier = 0.8
        })
    end
end

--------------------------------------------------
-- Events
--------------------------------------------------

script.on_init(update_caches)
script.on_configuration_changed(update_caches)
script.on_event(defines.events.on_runtime_mod_setting_changed, update_caches)

script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, function(event)
    if not settings.global["aub-enable-mod"].value then
        return
    end

    local entity = event.created_entity or event.entity
    if entity and entity.valid and entity.type == "transport-belt" then
        -- Only trigger transformations after exiting a concrete patch onto a normal tile.
        process_belt(entity)
    end
end)
