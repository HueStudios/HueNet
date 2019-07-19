--[[
Update package sent to the HueNet relays
Copyright (C) 2019  HueStudios

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

relay_func = function(update_parts, firmware_version)

  -- Library imports
  local modem = component.proxy(component.list("modem")())

  -- Random string generation
  local random_dictionary = "ABCDEF1234567890"
  local random_string = function(string_length, dictionary)
    local result = ""
    for i=1,string_length,1 do
      random_id = math.random(1, #dictionary)
      result = result .. string.sub(dictionary, random_id, random_id)
    end
    return result
  end

  --Utils
  local split_string = function(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
  end

  -- Relay initialization
  local remote_relays  = {}
  local remote_clients = {}
  local relay_id       = random_string(5, random_dictionary)
  for i = 2040, 2045 do
    modem.open(i)
  end

  -- Initialize modem
  modem.open(4200)
  if modem.isWireless() then
    modem.setStrength(400)
  end

  -- Forward updates
  local updating = {}

  -- Obtain updates
  local incoming_update_parts = {}
  local updater               = nil

  while true do
    -- Relay beacon
    modem.broadcast(2040, nil, "relay_beacon")

    -- Obtain updates pre-message
    if updater == nil then
      modem.broadcast(4200, firmware_version, "version")
    end
    local signal, _, from, port, _, remote_firmware_version,
        command, origin, destination, data, path = computer.pullSignal(5)

    -- Path initialization
    if path == nil then
      path = relay_id
    else
      path = path .. "," .. relay_id
    end

    -- Signal filtering
    if signal == "modem_message" then

      -- Network discovery
      if port == 2040 then
        if command == "relay_beacon" then
          relays[from] = true
        end
        if command == "client_register" then
          clients[from] = true
        end
        if command == "client_unregister" then
          clients[from] = nil
        end
      end

      -- Network transport
      if port > 2040 and port <= 2045 then

        -- Message sending
        if command == "send_message" then

          -- Prevent spoofing
          if clients[from] and origin ~= from then
            origin = from
          end

          -- Send to destination
          if clients[destination] then
            modem.send(destination, port, "send_message",
                origin, destination, data, path)
          else

            -- Relay message
            for k,v in pairs(relays) do
              path_parts = split_string(path, ",")

              -- Prevent message loops
              if path_parts[#path_parts] ~= k then
                modem.send(k, port, "send_message", origin, destination, data)
              end
            end
          end
        end

        -- Message broadcasting
        if command == "broadcast_message" then

          -- Prevent spoofing
          if clients[from] and origin ~= from then
            origin = from
          end

          -- Broadcast to clients
          for k,v in pairs(clients) do
            modem.send(k, port, "broadcast_message", origin, nil, data, path)
          end

          -- Broadcast to relays
          for k,v in pairs(relays) do
            path_parts = split_string(path, ",")

            -- Prevent message loops
            if path_parts[#path_parts] ~= k then
              modem.send(k, port, "broadcast_message", origin, nil, data, path)
            end
          end
        end
      end
      if port == 4200 then

        -- Obtain updates post-message
        if updater == nil then
          if remote_firmware_version ~= nil then
            if remote_firmware_version > firmware_version then
              modem.send(from, 4200, firmware_version, "update_me")
              updater = from
            end
          end
        else
          if part ~= nil and size ~= nil and data ~= nil then
            incoming_update_parts[part] = data
            if #incoming_update_parts == size then
              firmware_version = remote_firmware_version
              modem.send(from, 4200, firmware_version, "update_received")
              break
            end
          end
        end

        -- Forward updates post-messages
        if command == "update_me" and
            remote_firmware_version < firmware_version then
          updating[from] = 1
        end
        if command == "update_received" then
          updating[from] = nil
        end
      end
    end

    -- Forward updates to update clients
    for k, v in pairs(updating) do
      if v > #update_parts then
        updating[k] = 1
        v = 1
      end
      modem.send(k, 4200, firmware_version, v, #update_parts, update_parts[v])
      updating[k] = v + 1
    end
  end

  -- Compile and run received update
  local updateText = ""
  for i, v in ipairs(update_parts) do
    updateText = updateText .. v
  end
  updateFunction = load(updateText)()
  return updateFunction(update_parts, firmware_version)
end
return relay_func
