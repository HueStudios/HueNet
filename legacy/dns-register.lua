local machonet = require("machonet")
local dns_server = "7e93127f-cedd-4060-aaa1-55ffcad2caad"
local args = {...}
local serial = require("serialization")
if args[1] then
  if ("--register" == args[1]) then
    if args[2] then
      local connection = {}
      local function network_callback(message, port, from)
        local data = {}
        local function deserializeMessage()
          data = serial.unserialize(message)
          return nil
        end
        if pcall(deserializeMessage) then
          if data.response then
            print(("Registered as" .. args[2]))
            connection.disconnect()
            local file = io.open((args[2] .. ".cert"), "w")
            file:write(data.response)
            return file:close()
          end
        end
      end
      connection = machonet.connect(2040, dns_server, network_callback)
      print(serial.serialize(connection))
      local request = {name = args[2], query = "register"}
      return connection.send(serial.serialize(request))
    end
  else
    if ("--remove" == args[1]) then
      if args[2] then
        local connection = {}
        local function network_callback(message, port, from)
          local data = {}
          local function deserializeMessage()
            data = serial.unserialize(message)
            return nil
          end
          if pcall(deserializeMessage) then
            if data.response then
              print("Dns registration removed")
              return connection.disconnect()
            end
          end
        end
        local file = io.open(args[2], "r")
        if file then
          local certificate = file:read("*a")
          file:close()
          connection = machonet.connect(2040, dns_server, network_callback)
          local request = {certificate = certificate, query = "remove"}
          return connection.send(serial.serialize(request))
        end
      end
    end
  end
end
