local component = require("component")
local modem = component.modem
local event = require("event")
local serial = require("serialization")
local machonet = {}
local current_relay = {assigned = false}
local function ask_for_relay()
  return modem.broadcast(2042, "{hello=\"client\",force=\"force\"}")
end
local function disconnect_from_relay(addr)
  return modem.send(addr, 2042, "{bye=\"client\"}")
end
local function disconnect_from_all_relays()
  return modem.broadcast(2042, "{bye=\"client\"}")
end
local function disconnect_from_current_relay()
  if current_relay.assigned then
    disconnect_from_relay(current_relay.addr)
    current_relay = {assigned = false}
    return nil
  end
end
local function connect_to_relay()
  disconnect_from_current_relay()
  return ask_for_relay()
end
local listener_count = 0
local listeners = {}
local function remove_all_listeners()
  listeners = {}
  return nil
end
local function add_listener(port, addr, callback)
  modem.open(port)
  local id = (1 + #listeners)
  listener_count = (1 + listener_count)
  local this_listener = {["listener-id"] = listener_count,
      addr = addr, callback = callback, port = port}
  listeners[id] = this_listener
  return listener_count
end
local function remove_listener(id)
  local new_listeners = {}
  local port = 0
  for k, v in pairs(listeners) do
    local function _0_()
      if (v["listener-id"] == id) then
        port = v.port
        return nil
      end
    end
    _0_()
  end
  local listeners_in_port = 0
  for k, v in pairs(listeners) do
    local function _0_()
      if not (v["listener-id"] == id) then
        local function _0_()
          if (v.port == port) then
            listeners_in_port = (1 + listeners_in_port)
            return nil
          end
        end
        _0_()
        new_listeners[(1 + #new_listeners)] = v
        return nil
      end
    end
    _0_()
  end
  local function _0_()
    if (listeners_in_port == 0) then
      return modem.close(port)
    end
  end
  _0_()
  listeners = new_listeners
  return nil
end
local function send_to_addr(port, addr, message)
  if current_relay.assigned then
    local package = {msg = message, to = addr}
    return modem.send(current_relay.addr, port, serial.serialize(package))
  end
end
local function network_callback(nothing,
    receiver_addr, sender_addr, port, distance, message)
  local data = {}
  local function deserializeMessage()
    data = serial.unserialize(message)
    return nil
  end
  if pcall(deserializeMessage) then
    if current_relay.assigned then
      if (sender_addr == current_relay.addr) then
        if (data.from and data.msg) then
          for k, v in pairs(listeners) do
            local function _0_()
              if (((v.addr == "*") or
                  (v.addr == data.from)) and (v.port == port)) then
                return pcall(v.callback, data.msg, port, data.from)
              end
            end
            _0_()
          end
          return nil
        end
      else
        local function _0_()
          if data.relays then
            return disconnect_from_relay(sender_addr)
          end
        end
        _0_()
        if data.hello then
          if ((data.hello == "relay") and
              (distance < current_relay.distance)) then
            disconnect_from_relay(current_relay.addr)
            current_relay.assigned = true
            current_relay.addr = sender_addr
            current_relay.distance = distance
            return nil
          end
        end
      end
    else
      if data.hello then
        if (data.hello == "relay") then
          current_relay.assigned = true
          current_relay.addr = sender_addr
          current_relay.distance = distance
          return nil
        end
      end
    end
  end
end
event.listen("modem_message", network_callback)
modem.open(2042)
disconnect_from_all_relays()
connect_to_relay()
machonet.connect = function(port, addr, callback)
  local connection = nil
  local function _0_()
    if ((port >= 2040) and (port <= 2050) and not (port == 2042)) then
      local listener_id = add_listener(port, addr, callback)
      connection = {}
      connection.send = function(message)
        return send_to_addr(port, addr, message)
      end
      connection.disconnect = function()
        remove_listener(listener_id)
        connection.send = nil
        connection.disconnect = nil
        connection = nil
        return nil
      end
      return connection.disconnect
    end
  end
  _0_()
  return connection
end
return machonet
