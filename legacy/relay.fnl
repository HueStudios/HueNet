(local component (require :component))
(local modem component.modem)
(local event (require :event))
(local thread (require :thread))
(local term (require :term))
(local serial (require :serialization))
(local relayId "0")
(os.exit)
(for [i 2040 2050]
  (modem.open i)
  (print (.. i "/2050")))
(local relays {})
(var clients {})
(print "Machonet :)")
(fn beacon [force]
  (var discovery-data {})
  (when force
    (set discovery-data.force "force"))
  (set discovery-data.hello "relay")
  (modem.setStrength 400)
  (modem.broadcast 2042 (serial.serialize discovery-data))
  (term.write "B"))
(fn add-server [server s-list]
  (var already-added false)
  (each [k v (pairs s-list)]
    (when (= v.addr server.addr)
      (set already-added true)))
  (when (not already-added)
    (tset s-list (+ (# s-list) 1) server)
    (beacon)))
(fn remove-client [server]
  (var new-list {})
  (each [k v (pairs clients)]
    (when (not (= v.addr server.addr))
      (tset new-list (+ 1 (# new-list)) v)))
  (set clients new-list))
(beacon true)
(while true
  (local (_ _ from port distance message) (event.pull :modem_message))
  (var data {})
  (fn deserializeMessage []
    (set data (serial.unserialize message)))
  (if (pcall deserializeMessage)
    (do
      (if (or data.bye data.hello)
        (do
          (local this-server {})
          (set this-server.addr from)
          (set this-server.dist distance)
          (if data.hello
            (do
              (if (= data.hello "relay")
                (do
                  (add-server this-server relays)
                  (term.write "R")
                  (when data.force
                    (beacon)))
                (do
                  (add-server this-server clients)
                  (term.write "C")
                  (when data.force
                    (beacon)))))
            (do
              (when data.bye
                (remove-client this-server)
                (term.write "W")))))
        (do
          (var should-relay true)
          (if data.relays
            (do
              (each [k v (pairs data.relays)]
                (when (= v relayId)
                  (set should-relay false))))
            (do
              (set data.relays {})))
          (when should-relay
            (tset data.relays (+ 1 (# data.relays)) relayId)
            (if (not data.from)
              (set data.from from))
            (local reserialized-message (serial.serialize data))
            (if data.to
              (do
                (var found-target false)
                (each [k v (pairs clients)]
                  (when (= v.addr data.to)
                    (when (not (= v.addr from))
                      (set found-target (modem.send v.addr port reserialized-message))
                      (term.write "|"))))
                (when (not found-target)
                  (each [k v (pairs relays)]
                    (when (not (= v.addr from))
                      (modem.send v.addr port reserialized-message)
                      (term.write "<")))))
              (do
                (each [k v (pairs relays)]
                  (when (not (= v.addr from))
                    (modem.send v.addr port reserialized-message)
                    (term.write ">")))
                (each [k v (pairs clients)]
                  (when (not (= v.addr from))
                    (modem.send v.addr port reserialized-message)
                    (term.write "-")))))))))
    (do
      (term.write "X"))))
