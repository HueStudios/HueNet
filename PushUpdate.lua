--Library imports
local computer = require "computer"
local component = require "component"
local modem = component.modem

--Initialize modem
modem.open(4200)
modem.setStrength(400)

--Obtain console arguments
args = {...}

--Load update information from disk and console
local firmware_version = args[3]
update_parts = {}
update_file = io.open(args[2], "r")
counter = 1
while true do
  update_parts[counter] = update_file:read(32)
  if #update_parts[counter] ~= 32 then
    break
  end
  counter = counter + 1
end
update_file:close()

--List of servers currently being updated
updating = {}

while true do
  --Constantly broadcast firmware version
  modem.broadcast(4200, firmware_version)
  signal, _, from, port, _, remote_firmware_version, command = computer.pullSignal(1)
  if signal == "modem_message" and port == 4200 then

    --Respond to messages asking for updates
    if command == "update_me" and remote_firmware_version < firmware_version then
      updating[from] = 1
      print(from, "asked for update", firmware_version)
    end

    --Stop sending updates when completed
    if command == "update_received" then
      updating[from] = nil
      print(from, "finished update", firmware_version)
    end
  end

  --Send update chunks to each client
  for k, v in pairs(updating) do
    if v > #update_parts then
      updating[k] = 1
      v = 1
    end
    print("sending update chunk", v, "to", k)
    modem.send(k, 4200, firmware_version, v, #update_parts, update_parts[v])
    updating[k] = v + 1
  end
end
