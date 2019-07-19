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
local serial    = require("serialization")
local modem     = componen.modem

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
local current_access_point = nil
local awaiting_relay_response = false

local register_on_relay = function (relay_addr)
  modem.send(relay_addr, 2040, "client_register")
end

local unregister_on_relay = function (relay_addr)
  modem.send(relay_addr, 2040, "client_unregister")
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
end

local remove_listener = function (listener)
  listeners[this_listener.port][this_listener.remote_address][listener.id] = {}
end

-- Networking
local send_to_addr = function (port, remote_address, message)
  if current_access_point then
    modem.send(current_access_point, port, "send_message", nil, remote_address,
      message)
  end
end

local drop_access_point_request = function()
  current_access_point = nil
  awaiting_relay_response = false
end

drop_request_id = nil

local network_callback = function (_, local_address, sender_address, port,
    distance, _, command, origin, destination, data, path)
  if current_access_point == nil then
    if command == "relay_beacon" and not awaiting_relay_response then
      register_on_relay(sender_address)
      awaiting_relay_response = sender_address
      drop_request_id = event.timer(4, drop_access_point_request)
      return nil
    end
    if command == "client_accepted" then
        and awaiting_relay_response == sender_address then
      current_access_point = sender_address
      event.cancel(drop_request_id)
    end
    if command == "client_removed" then
      drop_access_point_request()
    end
    if command == "send_message" or command == "broadcast_message" then
      if sender_address == current_access_point then
        if listeners[port][origin] then
          for k,v in pairs(listeners[port][origin]) do
            pcall(v.callback, port, command, data, path))
          end
        end
      end
    end
  end
end

return HueNetLib
