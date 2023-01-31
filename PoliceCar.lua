local PoliceCarCache = {}

if not menu.is_trusted_mode_enabled(1 << 2) then 
    menu.notify("Natives must be enabled!", "PoliceCar", 3, 255)
    menu.exit()
end

local function setBlueLight(veh)
    vehicle.set_vehicle_neon_lights_color(veh, 136703)
    vehicle.set_vehicle_headlight_color(veh, 1)
end

local function setRedLight(veh)
    vehicle.set_vehicle_neon_lights_color(veh, 16711937)
    vehicle.set_vehicle_headlight_color(veh, 8)
end

local function setNoLight(veh, delay)
    for h = 0,3,1 do 
        vehicle.set_vehicle_neon_light_enabled(veh, h, false)
    end
    vehicle.set_vehicle_headlight_color(veh, 0)
    system.wait(delay)
    for i = 0,3,1 do 
        vehicle.set_vehicle_neon_light_enabled(veh, i, true)
    end
end

local function EnableLight(veh)
    for i = 0,3,1 do 
        vehicle.set_vehicle_neon_light_enabled(veh, i, true)
    end 
    for j = 0,1,1 do
        vehicle.set_vehicle_indicator_lights(veh, j, true)
    end
    vehicle.toggle_vehicle_mod(veh, 22, true)
end

local function DisableLight(veh)
    for h = 0,3,1 do 
        vehicle.set_vehicle_neon_light_enabled(veh, h, false)
    end
    for l = 0,1,1 do
        vehicle.set_vehicle_indicator_lights(veh, l, false)
    end
    vehicle.set_vehicle_headlight_color(veh, -1)
end

local player_main_menu = menu.add_player_feature("PoliceCar", "parent", 0)
local player_light_menu = menu.add_player_feature("Lights", "value_str", player_main_menu.id, function(f, pid)

    if PoliceCarCache[pid] and PoliceCarCache[pid].light_thread then
        menu.delete_thread(PoliceCarCache[pid].light_thread)
    end

    if f.on then
        if player.is_player_in_any_vehicle(pid) then 
            local player_vehicle = player.get_player_vehicle(pid)
            native.call(0x34E710FF01247C5A, player_vehicle, 2)
            native.call(0x8B7FD87F0DDB421E, player_vehicle, true)

            

            EnableLight(player_vehicle)
            local light_thread = menu.create_thread(function ()
                local flicker = f.value + 1
                local delay = 200 // flicker
                while(f.on) do
                    for j = 0,flicker,1 do
                        if flicker > 1 then
                            setNoLight(player_vehicle, delay)
                        end
                        setBlueLight(player_vehicle)
                        system.wait(delay)
                    end

                    for j = 0,flicker,1 do
                        if flicker > 1 then
                            setNoLight(player_vehicle, delay)
                        end
                        setRedLight(player_vehicle)
                        system.wait(delay)
                    end
                end
            end)

            PoliceCarCache[pid] = PoliceCarCache[pid] or {}
            PoliceCarCache[pid].light_thread = light_thread
            PoliceCarCache[pid].p_v = player_vehicle

        else 
            menu.notify("Player must be in a vehicle!", "PoliceCar", 3, 255)
        end
    else
        if PoliceCarCache[pid] and PoliceCarCache[pid].p_v then
            native.call(0x34E710FF01247C5A, PoliceCarCache[pid].p_v, 0)
            DisableLight(PoliceCarCache[pid].p_v)
        end
    end
end)

local light_options <const> = {
    "Normal",
    "2 Flash",
    "3 Flash"
}

player_light_menu:set_str_data(light_options)

menu.add_player_feature("Siren", "toggle", player_main_menu.id, function(f, pid)

    while not streaming.has_model_loaded(1127131465) do
        streaming.request_model(1127131465)
        system.wait(200)
    end

    if f.on then
        if player.is_player_in_any_vehicle(pid) then 
            local player_vehicle = player.get_player_vehicle(pid)

            local offset = v3(0,5,0)

            local coords = entity.get_entity_coords(player_vehicle)
            local heading = entity.get_entity_heading(player_vehicle)
            local model = player.get_player_model(pid)

            local siren_vehicle = vehicle.create_vehicle(1127131465, offset + coords, heading, true, false)
            local siren_ped = ped.create_ped(0, model, offset + coords, heading, true, false)

            local seat = vehicle.get_free_seat(siren_vehicle)
            ped.set_ped_into_vehicle(siren_ped, siren_vehicle, seat)

            native.call(0xF4924635A19EB37D, siren_vehicle, true)

            native.call(0xEA1C610A04DB6BBB, siren_vehicle, false, 0)
            native.call(0xEA1C610A04DB6BBB, siren_ped, false, 0)

            entity.attach_entity_to_entity(siren_vehicle, player_vehicle, 0, v3(0), v3(0), false, false, false, 0, true)
        
            PoliceCarCache[pid] = PoliceCarCache[pid] or {}
            PoliceCarCache[pid].siren_vehicle = siren_vehicle
            PoliceCarCache[pid].siren_ped = siren_ped

        else 
            menu.notify("Player must be in a vehicle!", "PoliceCar", 3, 255)
        end

    else
        if PoliceCarCache[pid] and PoliceCarCache[pid].siren_vehicle then
            entity.delete_entity(PoliceCarCache[pid].siren_ped)
            entity.delete_entity(PoliceCarCache[pid].siren_vehicle)
        end
    end
end)
