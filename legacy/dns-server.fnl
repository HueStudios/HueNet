(local machonet (require :machonet))
(local serial (require :serialization))
(var registers {})
(local charset [:a :b :c :d :e :f :0 :1 :2 :3 :4 :5 :6 :7 :8 :9])
(fn generate-certificate []
  (var result "")
  (for [i 1 16]
    (set result (.. result (. charset (math.random 1 16)))))
  result)
(fn network-callback [message port address]
  (var data {})
  (fn deserializeMessage []
    (set data (serial.unserialize message)))
  (when (pcall deserializeMessage)
    (var response {})
    (when data.query
      (print message)
      (when data.name
        (set response.name data.name)
        (when (= data.query "register")
          (var not-possible false)
          (each [k v (pairs registers)]
            (set not-possible (or not-possible (= v.name data.name))))
          (when (not not-possible)
            (var this-registration {})
            (set this-registration.name data.name)
            (set this-registration.address address)
            (set this-registration.certificate (generate-certificate))
            (tset registers (+ 1 (# registers)) this-registration)
            (set response.response this-registration.certificate)))
        (when (= data.query "lookup")
          (each [k v (pairs registers)]
            (when (= data.name v.name)
              (set response.response v.address)))))
      (when (= data.query "remove")
        (when data.certificate
          (var new-registries {})-
          (each [k v (pairs registers)]
            (when (= v.certificate data.certificate)
              (set response.response :ok))
            (when (not (= v.certificate data.certificate))
              (tset new-registries (+ 1 (# new-registries)) v)))
          (set registers new-registries))))
    (local connection (machonet.connect port address nil))
    (connection.send (serial.serialize response))
    (print (serial.serialize response))
    (connection.disconnect)))
(machonet.connect 2040 "*" network-callback)
