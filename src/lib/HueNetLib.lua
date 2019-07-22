--[[
Library for HueNet clients running OpenOS
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
local component = require("component")
local event     = require("event")
local modem     = component.modem

-- Utilities
local random_dictionary = "ABCDEF1234567890"
local random_string     = function(string_length, dictionary)
  local result = ""
  for i=1,string_length,1 do
    random_id = math.random(1, #dictionary)
    result = result .. string.sub(dictionary, random_id, random_id)
  end
  return result
end

-- Library table
HueNetLib = {}

-- Common relay utilities
local current_access_point    = nil
local awaiting_relay_response = false
local drop_request_id         = nil
local trying_to_connect       = false
local access_point_distance   = 0

-- Usage statistics
local sent_bytes = 0
local received_bytes = 0

local register_on_relay = function (relay_addr)
  modem.send(relay_addr, 2040, nil, "client_register")
  print("Trying to register on", relay_addr)
end

local unregister_on_relay = function (relay_addr)
  modem.send(relay_addr, 2040, nil, "client_unregister")
end

-- HueNet event listeners
local listeners = {}

local add_listener = function (port, remote_address, callback)
  local this_listener = {}
  if listeners[port] == nil then
    listeners[port] = {}
  end
  if listeners[remote_address] == nil then
    listeners[remote_address] = {}
  end
  this_listener.id             = random_string(8, random_dictionary)
  this_listener.remote_address = remote_address
  this_listener.callback       = callback
  this_listener.port           = port
  listeners[port][remote_address][this_listener.id] = this_listener
  return this_listener
end

local remove_listener = function (listener)
  listeners[this_listener.port][this_listener.remote_address][listener.id] = {}
end

-- Networking
local send_to_addr = function (port, remote_address, message)
  if current_access_point then
    sent_bytes = sent_bytes + #message
    modem.send(current_access_point, port, "send_message", nil, remote_address,
      message)
  end
end

local drop_access_point_request = function()
  current_access_point = nil
  access_point_distance = nil
  awaiting_relay_response = false
end

local network_callback = function (_, local_address, sender_address, port,
    distance, _, command, origin, destination, data, path)
  print(command)
  if current_access_point == nil then
    if command == "relay_beacon" and (not awaiting_relay_response)
        and trying_to_connect then
      register_on_relay(sender_address)
      awaiting_relay_response = sender_address
      drop_request_id = event.timer(4, drop_access_point_request)
      return nil
    end
    if command == "client_accepted"
        and awaiting_relay_response == sender_address
        and trying_to_connect then
      access_point_distance = distance
      current_access_point = sender_address
      event.cancel(drop_request_id)
    end
  else
    if command == "client_removed" then
      drop_access_point_request()
    end
    if command == "send_message" or command == "broadcast_message" then
      if sender_address == current_access_point then
        if listeners[port][origin] then
          received_bytes = received_bytes + #data
          for k,v in pairs(listeners[port][origin]) do
            pcall(v.callback, port, command, data, path)
          end
        end
      end
    end
  end
end

event.listen("modem_message", network_callback)

-- Library exports
HueNetLib.Enable = function ()
  trying_to_connect = true
  for i = 2040, 2045 do
    modem.open(i)
  end
end

HueNetLib.Disable = function ()
  trying_to_connect = false
  if current_access_point then
    unregister_on_relay(current_access_point)
  end
  for i = 2040, 2045 do
    modem.close(i)
  end
end

HueNetLib.IsEnabled = function ()
  return trying_to_connect
end

HueNetLib.IsConnected = function ()
  return current_access_point ~= nil
end

HueNetLib.GetCurrentAccessPoint = function ()
  if HueNetLib.IsConnected() then
    return current_access_point
  else
    return ""
  end
end

HueNetLib.GetReceivedBytes = function()
  return received_bytes
end

HueNetLib.GetSentBytes = function()
  return sent_bytes
end

HueNetLib.GetSignalLevel = function ()
  if current_access_point then
    if modem.isWireless() then
      return 1
    else
      if access_point_distance ~= nil then
        return 1 - (access_point_distance / 400.0)
      else
        return 0
      end
    end
  end
  return 0
end

HueNetLib.Connect = function(port, remote_address, callback)
  if port > 2040 and port <= 2045 then
    this_listener = add_listener(port, remote_address, callback)
    connection    = {}
    connection.Send = function(message)
      return send_to_addr(port, remote_address, message)
    end
    connection.Disconnect = function ()
      remove_listener(this_listener)
      connection.Send       = nil
      connection.Disconnect = nil
      connection            = nil
    end
    return connection
  end
end

return HueNetLib
