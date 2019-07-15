(local machonet (require :machonet))
(local dns-server :7e93127f-cedd-4060-aaa1-55ffcad2caad)
(local args [...])
(local serial (require :serialization))
(if (. args 1)
  (if (= "--register" (. args 1))
    (do
      (when (. args 2)
        (var connection {})
        (fn network-callback [message port from]
          (var data {})
          (fn deserializeMessage []
            (set data (serial.unserialize message)))
          (when (pcall deserializeMessage)
            (when data.response
              (print (.. "Registered as" (. args 2)))
              (connection.disconnect)
              (local file (io.open (.. (. args 2) ".cert") :w))
              (: file :write data.response)
              (: file :close))))
        (set connection (machonet.connect 2040 dns-server network-callback))
        (print (serial.serialize connection))
        (local request {:query :register :name (. args 2)})
        (connection.send (serial.serialize request))))
    (do
      (if (= "--remove" (. args 1))
        (when (. args 2)
          (var connection {})
          (fn network-callback [message port from]
            (var data {})
            (fn deserializeMessage []
              (set data (serial.unserialize message)))
            (when (pcall deserializeMessage)
              (when data.response
                (print "Dns registration removed")
                (connection.disconnect))))
          (local file (io.open (. args 2) :r))
          (when file
            (local certificate (: file :read :*a))
            (: file :close)
            (set connection (machonet.connect 2040 dns-server network-callback))
            (local request {:query :remove :certificate certificate})
            (connection.send (serial.serialize request))))))))
