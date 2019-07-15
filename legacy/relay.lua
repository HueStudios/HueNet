local component = require("component")
local modem = component.modem
local event = require("event")
local thread = require("thread")
local term = require("term")
local serial = require("serialization")
local relayId = "0"
os.exit()
for i = 2040, 2050 do
  modem.open(i)
  print((i .. "/2050"))
end
local relays = {}
local clients = {}
print("Machonet :)")
local function beacon(force)
  local discovery_data = {}
  local function _0_()
    if force then
      discovery_data.force = "force"
      return nil
    end
  end
  _0_()
  discovery_data.hello = "relay"
  modem.setStrength(400)
  modem.broadcast(2042, serial.serialize(discovery_data))
  return term.write("B")
end
local function add_server(server, s_list)
  local already_added = false
  for k, v in pairs(s_list) do
    local function _0_()
      if (v.addr == server.addr) then
        already_added = true
        return nil
      end
    end
    _0_()
  end
  if not already_added then
    s_list[(#s_list + 1)] = server
    return beacon()
  end
end
local function remove_client(server)
  local new_list = {}
  for k, v in pairs(clients) do
    local function _0_()
      if not (v.addr == server.addr) then
        new_list[(1 + #new_list)] = v
        return nil
      end
    end
    _0_()
  end
  clients = new_list
  return nil
end
beacon(true)
while true do
  local _, _, from, port, distance, message = event.pull("modem_message")
  local data = {}
  local function deserializeMessage()
    data = serial.unserialize(message)
    return nil
  end
  local function _0_(...)
    if pcall(deserializeMessage) then
      if (data.bye or data.hello) then
        local this_server = {}
        this_server.addr = from
        this_server.dist = distance
        if data.hello then
          if (data.hello == "relay") then
            add_server(this_server, relays)
            term.write("R")
            if data.force then
              return beacon()
            end
          else
            add_server(this_server, clients)
            term.write("C")
            if data.force then
              return beacon()
            end
          end
        else
          if data.bye then
            remove_client(this_server)
            return term.write("W")
          end
        end
      else
        local should_relay = true
        local function _0_(...)
          if data.relays then
            for k, v in pairs(data.relays) do
              local function _0_(...)
                if (v == relayId) then
                  should_relay = false
                  return nil
                end
              end
              _0_(...)
            end
            return nil
          else
            data.relays = {}
            return nil
          end
        end
        _0_(...)
        if should_relay then
          data.relays[(1 + #data.relays)] = relayId
          local function _1_(...)
            if not data.from then
              data.from = from
              return nil
            end
          end
          _1_(...)
          local reserialized_message = serial.serialize(data)
          if data.to then
            local found_target = false
            for k, v in pairs(clients) do
              local function _2_(...)
                if (v.addr == data.to) then
                  if not (v.addr == from) then
                    found_target = modem.send(v.addr, port, reserialized_message)
                    return term.write("|")
                  end
                end
              end
              _2_(...)
            end
            if not found_target then
              for k, v in pairs(relays) do
                local function _2_(...)
                  if not (v.addr == from) then
                    modem.send(v.addr, port, reserialized_message)
                    return term.write("<")
                  end
                end
                _2_(...)
              end
              return nil
            end
          else
            for k, v in pairs(relays) do
              local function _2_(...)
                if not (v.addr == from) then
                  modem.send(v.addr, port, reserialized_message)
                  return term.write(">")
                end
              end
              _2_(...)
            end
            for k, v in pairs(clients) do
              local function _2_(...)
                if not (v.addr == from) then
                  modem.send(v.addr, port, reserialized_message)
                  return term.write("-")
                end
              end
              _2_(...)
            end
            return nil
          end
        end
      end
    else
      return term.write("X")
    end
  end
  _0_(...)
end
return nil
