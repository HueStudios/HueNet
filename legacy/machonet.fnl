(local component (require :component))
(local modem component.modem)
(local event (require :event))
(local serial (require :serialization))
(local machonet {})
(var current-relay {:assigned false})
(fn ask-for-relay []
  (modem.broadcast 2042 "{hello=\"client\",force=\"force\"}"))
(fn disconnect-from-relay [addr]
  (modem.send addr 2042 "{bye=\"client\"}"))
(fn disconnect-from-all-relays []
  (modem.broadcast 2042 "{bye=\"client\"}"))
(fn disconnect-from-current-relay []
  (when current-relay.assigned
    (disconnect-from-relay current-relay.addr)
    (set current-relay {:assigned false})))
(fn connect-to-relay []
  (disconnect-from-current-relay)
  (ask-for-relay))
(var listener-count 0)
(var listeners {})
(fn remove-all-listeners []
  (set listeners {}))
(fn add-listener [port addr callback]
  (modem.open port)
  (local id (+ 1 (# listeners)))
  (set listener-count (+ 1 listener-count))
  (local this-listener {:port port :addr addr :callback callback :listener-id listener-count})
  (tset listeners id this-listener)
  listener-count)
(fn remove-listener [id]
  (local new-listeners {})
  (var port 0)
  (each [k v (pairs listeners)]
    (when (= v.listener-id id)
      (set port v.port)))
  (var listeners-in-port 0)
  (each [k v (pairs listeners)]
    (when (not (= v.listener-id id))
      (when (= v.port port)
        (set listeners-in-port (+ 1 listeners-in-port)))
      (tset new-listeners (+ 1 (# new-listeners)) v)))
  (when (= listeners-in-port 0)
    (modem.close port))
  (set listeners new-listeners))
(fn send-to-addr [port addr message]
  (when current-relay.assigned
    (local package {:to addr :msg message})
    (modem.send current-relay.addr port (serial.serialize package))))
(fn network-callback [nothing receiver-addr sender-addr port distance message]
  (var data {})
  (fn deserializeMessage []
    (set data (serial.unserialize message)))
  (when (pcall deserializeMessage)
    (if current-relay.assigned
      (do
        (if (= sender-addr current-relay.addr)
          (do
            (when (and data.from data.msg)
              (each [k v (pairs listeners)]
                (when (and (or (= v.addr "*") (= v.addr data.from)) (= v.port port))
                  (pcall v.callback data.msg port data.from)))))
          (do
            (when data.relays
              (disconnect-from-relay sender-addr))
            (when data.hello
              (when (and (= data.hello "relay") (< distance current-relay.distance))
                (disconnect-from-relay current-relay.addr)
                (set current-relay.assigned true)
                (set current-relay.addr sender-addr)
                (set current-relay.distance distance))))))
      (do
        (when data.hello
          (when (= data.hello "relay")
            (set current-relay.assigned true)
            (set current-relay.addr sender-addr)
            (set current-relay.distance distance)))))))
(event.listen :modem_message network-callback)
(modem.open 2042)
(disconnect-from-all-relays)
(connect-to-relay)
(fn machonet.connect [port addr callback]
  (var connection nil)
  (when (and (>= port 2040) (<= port 2050) (not (= port 2042)))
    (local listener-id (add-listener port addr callback))
    (set connection {})
    (fn connection.send [message]
      (send-to-addr port addr message))
    (fn connection.disconnect []
      (remove-listener listener-id)
      (set connection.send nil)
      (set connection.disconnect nil)
      (set connection nil)))
  connection)
machonet
