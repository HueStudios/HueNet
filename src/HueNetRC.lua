--[[
Controller front-end for HueNetLib
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
local HueNetLib = require("HueNetLib")

local help = function()
  print("HueNet  Copyright (C) 2019 HueStudios")
  print("This program comes with ABSOLUTELY NO WARRANTY.")
  print("Available commands: ")
  print("HueNetRC license_warranty   - Display license warranty details.")
  print("HueNetRC license_conditions - Display license conditions.")
  print("HueNetRC license            - Display the full GNU GPL3 license.")
  print("HueNetRC enable             - Stablish a connection to the HueNet.")
  print("HueNetRC disable            - Discard your connection to the HueNet.")
  print("HueNetRC status             - Display the status of your HueNet connection.")
end

args = {...}

if #args > 1 then
  print("Unexpected number of arguments.")
  os.exit()
end

if #args == 0 then

end
