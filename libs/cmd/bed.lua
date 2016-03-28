-- bed is a test executable. it generates udp packets and sends them to a
-- greenhouse instance.
local uv = require('uv')
local packet =
[[info:me.com
 time:12341234
 hostname:me.com
disk:/dev/sda
 avail=1024
 used=1024
cpu:1
 sys=0.5
 usr=0.5
 idle=99.0
cpu:2
 sys=0.5
 usr=0.5
 idle=99.0
sensor:1
 temp=85.0
 pressure=1
 sunlight=55.2
sensor:2
 temp=85.0
 pressure=1
 sunlight=55.2]]

return function()
  local socket = uv.new_udp()
  socket:open(0)
  local timer = uv.new_timer()
  uv.timer_start(timer, 1000, 1000, function()
    p("sending packet")

    socket:send(packet,"127.0.0.1",1234)
  end)
end