--[[
Utility to download the latest HueNet stack from github
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
component = require("component")
filesystem = require("filesystem")
internet = component.internet

-- Files
local files = {
  ["https://raw.githubusercontent.com/HueStudios/HueNet/master/src/etc/rc.d/HueNet.lua"]="/etc/rc.d/HueNet.lua",
  ["https://raw.githubusercontent.com/HueStudios/HueNet/master/src/lib/HueNetLib.lua"]="/lib/HueNetLib.lua"
}

for url, destination in pairs(files) do
  print("Downloading", url, "to", destination)
  if filesystem.exists(destination) then
    filesystem.remove(destination)
  end
  local local_file = io.open(destination, "w")
  local request = internet.request(url)
  while true do
    chunk = request.read(64)
    if chunk == nil then
      break
    else
      local_file:write(chunk)
    end
  end
  for chunk in internet.request(url) do
    local_file:write(chunk)
  end
  print("Downloaded", url)
  local_file:close()
end
