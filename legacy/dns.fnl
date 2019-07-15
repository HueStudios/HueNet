(local machonet (require :machonet))
(local dns-server :7e93127f-cedd-4060-aaa1-55ffcad2caad)
(local serial (require :serialization))
(local dns {})
(fn dns.lookup [name callback]
  (var connection {})
  (fn network-callback [message port from]
    (var data {})
    (fn deserializeMessage []
      (set data (serial.unserialize message)))
    (when (pcall deserializeMessage)
      (when data.response
        (when (= data.name name)
          (pcall callback data.response name)
          (connection.disconnect)))))
  (set connection (machonet.connect 2040 dns-server network-callback))
  (local request {:query :lookup :name name})
  (connection.send (serial.serialize request)))
dns
