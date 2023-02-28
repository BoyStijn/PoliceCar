local PoliceCarCache = {}   -- Cache for Player Vehicle, Police Vehicle, Ped and Light Thread
local version = "1.8"       -- Current Script Version for Auto Update
local json = { _version = "0.1.2" } -- Json Lib

local light_options <const> = {
    "2 Flash",
    "3 Flash",
    "Normal",
}

-- Check for Natives
if not menu.is_trusted_mode_enabled(1 << 2) then 
    menu.notify("Natives must be enabled!", "PoliceCar", 3, 255)
    menu.exit()
end

-- Light functions
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

local function doLights(f, pid)

    if PoliceCarCache[pid] and PoliceCarCache[pid].light_thread then
        menu.delete_thread(PoliceCarCache[pid].light_thread)
    end

    if f.on then
        if player.is_player_in_any_vehicle(pid) then 
            local player_vehicle = player.get_player_vehicle(pid)
            native.call(0x34E710FF01247C5A, player_vehicle, 2)
            native.call(0x8B7FD87F0DDB421E, player_vehicle, true)

            local array_size = #light_options

            EnableLight(player_vehicle)
            local light_thread = menu.create_thread(function ()
                local flicker = f.value + 2
                if f.value > #light_options - 2 then
                    flicker = 1
                end
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
end

-- Siren function
local function doSiren(f, pid)

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

            entity.attach_entity_to_entity(siren_vehicle, player_vehicle, 0, v3(0, 0, -1), v3(0), false, false, false, 0, true)

            native.call(0xBE5C1255A1830FF5, player_vehicle, true)

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
end

-- Start function
local start_thread = menu.create_thread(function ()

    --  Check for HTTP
    if not menu.is_trusted_mode_enabled(1 << 3) then 
        menu.notify("Auto Updater Failed! [Http not enabled]", "PoliceCar", 3, 255)
    else
        -- Check for update
        local response_code, response_body, response_headers = web.get("https://api.github.com/repos/BoyStijn/PoliceCar/releases/latest", {
            "User-Agent: gta5",
            "Accept: application/vnd.github+json",
        });
        if response_code == 200 then

            local parsed_body = json.decode(response_body)

            local github_version = parsed_body.tag_name
            local release_assets = parsed_body.assets

            print("TagName: " .. github_version)

            local asset_url = release_assets[0].url
        
            print("AssetUrl: " .. asset_url)

            if github_version ~= version then
                menu.notify("Update Available!\nNew version: v" .. github_version .. "\nDownloading new version...", "PoliceCar", 3, 255)

                local response_code, response_body, response_headers = web.request(asset_url, {
                    headers = {
                        "Accept: application/octet-stream",
                        "User-Agent: gta5"
                    },
                    method = 'get',
                    redirects = true
                })

                print(response_code)
                print(response_body)
                print(tostring(response_headers))

                if response_code == 200 then
                    local file_path = utils.get_appdata_path("PopstarDevs", "2Take1Menu") .. "\\scripts\\PoliceCar.lua"
                    local script_file = io.open(file_path , "wb")
                    if script_file ~= nil then
                        script_file:write(response_body)
                        script_file:flush()
                        script_file:close()
                        menu.notify("PoliceCar has been updated!\n", "PoliceCar", 3, 255)
                        menu.exit()
                    else
                        menu.notify("Auto Updater Failed! [Failed to save file]", "PoliceCar", 3, 255)
                    end
                else
                    menu.notify("Auto Updater Failed! [Failed to download latest release]", "PoliceCar", 3, 255)
                end
            else
                menu.notify("PoliceCar is up to date!", "PoliceCar", 3, 255)
            end

        else
            menu.notify("Auto Updater Failed! [Can't get latest release]", "PoliceCar", 3, 255)
        end
    end

    -- Register Menu headers
    local player_main_menu = menu.add_player_feature("PoliceCar", "parent", 0)
    local player_main_local_menu = menu.add_feature("PoliceCar", "parent", 0)
    
    -- Register Light Option
    -- @deprecated local player_light_menu = menu.add_player_feature("Lights", "value_str", player_main_menu.id, doLights)
    local player_light_local_menu = menu.add_feature("Lights", "value_str", player_main_local_menu.id, function (f)
        doLights(f, player.player_id())
    end)

    -- Set Light Option names
    --player_light_menu:set_str_data(light_options)
    player_light_local_menu:set_str_data(light_options)
    
    -- Register Siren Option
    menu.add_player_feature("Siren", "toggle", player_main_menu.id, doSiren)
    menu.add_feature("Siren", "toggle", player_main_local_menu.id, function (f)
        doSiren(f, player.player_id())
    end)

end)


-- JSON Lib 

-- Copyright (c) 2020 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local escape_char_map = {
    [ "\\" ] = "\\",
    [ "\"" ] = "\"",
    [ "\b" ] = "b",
    [ "\f" ] = "f",
    [ "\n" ] = "n",
    [ "\r" ] = "r",
    [ "\t" ] = "t",
}
  
local escape_char_map_inv = { [ "/" ] = "/" }

for k, v in pairs(escape_char_map) do
    escape_char_map_inv[v] = k
end

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end

local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
  [ "true"  ] = true,
  [ "false" ] = false,
  [ "null"  ] = nil,
}


local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[str:sub(i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end


local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error( string.format("%s at line %d col %d", msg, line_count, col_count) )
end


local function codepoint_to_utf8(n)
  -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
  local f = math.floor
  if n <= 0x7f then
    return string.char(n)
  elseif n <= 0x7ff then
    return string.char(f(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff then
    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
  elseif n <= 0x10ffff then
    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                       f(n % 4096 / 64) + 128, n % 64 + 128)
  end
  error( string.format("invalid unicode codepoint '%x'", n) )
end


local function parse_unicode_escape(s)
  local n1 = tonumber( s:sub(1, 4),  16 )
  local n2 = tonumber( s:sub(7, 10), 16 )
   -- Surrogate pair?
  if n2 then
    return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
  else
    return codepoint_to_utf8(n1)
  end
end


local function parse_string(str, i)
  local res = ""
  local j = i + 1
  local k = j

  while j <= #str do
    local x = str:byte(j)

    if x < 32 then
      decode_error(str, j, "control character in string")

    elseif x == 92 then -- `\`: Escape
      res = res .. str:sub(k, j - 1)
      j = j + 1
      local c = str:sub(j, j)
      if c == "u" then
        local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                 or str:match("^%x%x%x%x", j + 1)
                 or decode_error(str, j - 1, "invalid unicode escape in string")
        res = res .. parse_unicode_escape(hex)
        j = j + #hex
      else
        if not escape_chars[c] then
          decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
        end
        res = res .. escape_char_map_inv[c]
      end
      k = j + 1

    elseif x == 34 then -- `"`: End of string
      res = res .. str:sub(k, j - 1)
      return res, j + 1
    end

    j = j + 1
  end

  decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = str:sub(i, x - 1)
  local n = tonumber(s)
  if not n then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  return n, x
end


local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = str:sub(i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  return literal_map[word], x
end


local function parse_array(str, i)
  local res = {}
  local n = 0
  i = i + 1
  while 1 do
    local x
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if str:sub(i, i) == "]" then
      i = i + 1
      break
    end
    -- Read token
    x, i = parse(str, i)
    res[n] = x
    n = n + 1
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "]" then break end
    if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
  end
  return res, i
end


local function parse_object(str, i)
  local res = {}
  i = i + 1
  while 1 do
    local key, val
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if str:sub(i, i) == "}" then
      i = i + 1
      break
    end
    -- Read key
    if str:sub(i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse(str, i)
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value
    val, i = parse(str, i)
    -- Set
    res[key] = val
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "}" then break end
    if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
  end
  return res, i
end


local char_func_map = {
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_literal,
  [ "f" ] = parse_literal,
  [ "n" ] = parse_literal,
  [ "[" ] = parse_array,
  [ "{" ] = parse_object,
}


parse = function(str, idx)
  local chr = str:sub(idx, idx)
  local f = char_func_map[chr]
  if f then
    return f(str, idx)
  end
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


function json.decode(str)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  local res, idx = parse(str, next_char(str, 1, space_chars, true))
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end
  return res
end

