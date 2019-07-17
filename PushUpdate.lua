--[[
Utility to push update packages to nearby relays
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

-- Library imports
local computer = require "computer"
local component = require "component"
local modem = component.modem

-- Initialize modem
modem.open(4200)
if modem.isWireless() then
  modem.setStrength(400)
end

-- Obtain console arguments
args = {...}

-- Load update information from disk and console
local firmware_version = args[3]
update_parts = {}
update_file = io.open(args[2], "r")
counter = 1
while true do
  update_parts[counter] = update_file:read(32)
  if #update_parts[counter] ~= 32 then
    break
  end
  counter = counter + 1
end
update_file:close()

-- List of servers currently being updated
updating = {}

while true do
  -- Constantly broadcast firmware version
  modem.broadcast(4200, firmware_version)
  signal, _, from, port, _, remote_firmware_version,
      command = computer.pullSignal(1)
  if signal == "modem_message" and port == 4200 then

    -- Respond to messages asking for updates
    if command == "update_me" and
        remote_firmware_version < firmware_version then
      updating[from] = 1
      print(from, "asked for update", firmware_version)
    end

    -- Stop sending updates when completed
    if command == "update_received" then
      updating[from] = nil
      print(from, "finished update", firmware_version)
    end
  end

  -- Send update chunks to each client
  for k, v in pairs(updating) do
    if v > #update_parts then
      updating[k] = 1
      v = 1
    end
    print("sending update chunk", v, "to", k)
    modem.send(k, 4200, firmware_version, v, #update_parts, update_parts[v])
    updating[k] = v + 1
  end
end
