local machonet = require("machonet")
local serial = require("serialization")
local registers = {}
local charset = {"a", "b", "c", "d", "e", "f",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}
local function generate_certificate()
  local result = ""
  for i = 1, 16 do
    result = (result .. charset[math.random(1, 16)])
  end
  return result
end
local function network_callback(message, port, address)
  local data = {}
  local function deserializeMessage()
    data = serial.unserialize(message)
    return nil
  end
  if pcall(deserializeMessage) then
    local response = {}
    local function _0_()
      if data.query then
        print(message)
        local function _0_()
          if data.name then
            response.name = data.name
            local function _0_()
              if (data.query == "register") then
                local not_possible = false
                for k, v in pairs(registers) do
                  not_possible = (not_possible or (v.name == data.name))
                end
                if not not_possible then
                  local this_registration = {}
                  this_registration.name = data.name
                  this_registration.address = address
                  this_registration.certificate = generate_certificate()
                  registers[(1 + #registers)] = this_registration
                  response.response = this_registration.certificate
                  return nil
                end
              end
            end
            _0_()
            if (data.query == "lookup") then
              for k, v in pairs(registers) do
                local function _1_()
                  if (data.name == v.name) then
                    response.response = v.address
                    return nil
                  end
                end
                _1_()
              end
              return nil
            end
          end
        end
        _0_()
        if (data.query == "remove") then
          if data.certificate then
            local new_registries = {}
            for k, v in pairs(registers) do
              local function _1_()
                if (v.certificate == data.certificate) then
                  response.response = "ok"
                  return nil
                end
              end
              _1_()
              local function _2_()
                if not (v.certificate == data.certificate) then
                  new_registries[(1 + #new_registries)] = v
                  return nil
                end
              end
              _2_()
            end
            registers = new_registries
            return nil
          end
        end
      end
    end
    _0_()
    local connection = machonet.connect(port, address, nil)
    connection.send(serial.serialize(response))
    print(serial.serialize(response))
    return connection.disconnect()
  end
end
return machonet.connect(2040, "*", network_callback)
