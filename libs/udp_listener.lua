-- udp_listener listens for udp packets and sends them to the parser and then
-- stores them in the store
local format = require('format')
local uv = require('uv')
return function(store)
  socket = uv.new_udp()
  socket:bind("127.0.0.1",1234)
  socket:recv_start(function(err, data, sender, opts)
    if err ~= nil then
      error(err)
    end
    if data == nil then
      return
    end

    err,parsed = format.parse(data)
    if err ~= nil then
      return
    end
    store:insert(parsed)
  end)
end
