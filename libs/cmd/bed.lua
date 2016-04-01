-- bed is a test executable. it generates udp packets and sends them to a
-- greenhouse instance.
local uv = require('uv')
local json = require('json')
local data =
{
  info = {
    keys= {hostname="me.com"},
    values= {
      count = 0,
      time = 12341234,
      hostname = "me.com"
    }
  },
  disk = {
    keys= {path="/dev/sda"},
    values= {
      avail = 1024,
      used = 1024
    }
  },
  cpu = {
    keys= {cpu="1"},
    values= {
      sys = 0.5,
      usr = 0.5,
      idle = 99.0
    }
  },
  sensor = {
    keys= {sensor="1"},
    values= {
      temp = 85.0,
      pressure = 1,
      sunlight = 55.2
    }
  }
}

return function()

  local socket = uv.new_udp()
  socket:open(0)
  local timer = uv.new_timer()
  uv.timer_start(timer, 100, 100, function()
    data.info.values.count = data.info.values.count + 1

    packet = json.encode(data)
    socket:send(packet,"127.0.0.1",1234)
  end)
end
