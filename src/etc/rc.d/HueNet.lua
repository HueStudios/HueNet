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

start = function ()
  if not HueNetLib.IsEnabled() then
    HueNetLib.Enable()
  else
    print("HueNet has already been started!")
  end
end

stop = function ()
  if HueNetLib.IsEnabled() then
    HueNetLib.Disable()
  else
    print("HueNet is already stopped!")
  end
end

status = function ()
  if HueNetLib.IsEnabled() then
    print("Status: active.")
    print("Network connected: " .. HueNetLib.IsConnected())
    print("Access point: " .. HueNetLib.GetCurrentAccessPoint())
    print("Signal level: " .. HueNetLib.GetSignalLevel() * 100 .. "%")
    print("Bytes RX: " .. HueNetLib.GetReceivedBytes())
    print("Bytes TX: " .. HueNetLib.GetSentBytes())
  else
    print("Status: stopped.")
  end
end

help = function()
  print("HueNet  Copyright (C) 2019 HueStudios")
  print("This program comes with ABSOLUTELY NO WARRANTY.")
  print("Available commands: ")
  print("rc HueNet start              - Stablish a connection to the HueNet.")
  print("rc HueNet stop               - Discard your connection to the HueNet.")
  print("rc HueNet restart            - Stop and then start.")
  print("rc HueNet enable             - Start on boot.")
  print("rc HueNet disable            - Disable start on boot.")
  print("rc HueNet status             - Display the status of your HueNet connection.")
  print("rc HueNet help               - Display this message.")
end
