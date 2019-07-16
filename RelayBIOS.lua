--Bios running in the relays. Flash into the microcontroller's Eeprom.
--Copyright (C) 2019  HueStudios

--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.

--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more details.

--You should have received a copy of the GNU General Public License
--along with this program.  If not, see <http://www.gnu.org/licenses/>.


--Local firmware version
local firmware_version = 0

--Library imports
local modem = component.proxy(component.list("modem")())

--Modem intialization
modem.open(4200)
modem.setStrength(400)

--Update receive variables
updater      = nil
update_parts = {}

while true do

  --Broadcast firmware version
  if updater == nil then
    modem.broadcast(4200, firmware_version)
  end

  signal, _, from, port, _, remote_firmware_version, part, size, data = computer.pullSignal(10)

  --Update timeout
  if signal == nil and updater ~= nil then
    updater = nil
    update  = nil
  end

  --Signal filtering
  if signal == "modem_message" and port == 4200 then
    if updater == nil then
      if remote_firmware_version ~= nil then
        if remote_firmware_version > firmware_version then

          --Request update from remote
          modem.send(from, 4200, firmware_version, "update_me")
          updater = from
        end
      end
    else

      --Obtain update chunks
      if part ~= nil and size ~= nil and data ~= nil then
        update_parts[part] = data
        if #update_parts == size then
          firmware_version = remote_firmware_version

          --Confirm update reception
          modem.send(from, 4200, firmware_version, "update_received")
          break
        end
      end
    end
  end
end

--Reconstruct text string from update
updateText = ""
for i, v in ipairs(update_parts) do
  updateText = updateText .. v
end

--Run the update payload
updateFunction = load(updateText)()
updateFunction(update_parts, firmware_version)
