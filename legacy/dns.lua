local machonet = require("machonet")
local dns_server = "7e93127f-cedd-4060-aaa1-55ffcad2caad"
local serial = require("serialization")
local dns = {}
dns.lookup = function(name, callback)
  local connection = {}
  local function network_callback(message, port, from)
    local data = {}
    local function deserializeMessage()
      data = serial.unserialize(message)
      return nil
    end
    if pcall(deserializeMessage) then
      if data.response then
        if (data.name == name) then
          pcall(callback, data.response, name)
          return connection.disconnect()
        end
      end
    end
  end
  connection = machonet.connect(2040, dns_server, network_callback)
  local request = {name = name, query = "lookup"}
  return connection.send(serial.serialize(request))
end
return dns
