local firmware_version = 0

local modem = component.proxy(component.list("modem")())

modem.open(4200)
modem.setStrength(400)

updater = nil
update_parts = {}

while true do
  if updater == nil then
    modem.broadcast(4200, firmware_version)
  end
  signal, _, from, port, _, remote_firmware_version, part, size, data = computer.pullSignal(10)
  if signal == nil and updater ~= nil then
    updater = nil
    update = nil
  end
  if signal == "modem_message" and port == 4200 then
    if updater == nil then
      if remote_firmware_version ~= nil then
        if remote_firmware_version > firmware_version then
          modem.send(from, 4200, firmware_version, "update_me")
          updater = from
        end
      end
    else
      if part ~= nil and size ~= nil and data ~= nil then
        update_parts[part] = data
        if #update_parts == size then
          firmware_version = remote_firmware_version
          modem.send(from, 4200, firmware_version, "update_received")
          break
        end
      end
    end
  end
end

updateText = ""
for i, v in ipairs(update_parts) do
  updateText = updateText .. v
end

updateFunction = load(updateText)()
updateFunction(updateText, firmware_version)
