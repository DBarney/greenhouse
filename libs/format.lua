local format = {}

local incr = 0
function format.parse(data)
  incr = incr + 1
  return {
    ["info:me.com"] = {
      time = 12341234,
      hostname = "me.com"
    },
    ["disk:/dev/sda"] = {
      avail = 1024,
      used = 1024
    },
    ["cpu:1"] = {
      sys = 0.5,
      usr = 0.5,
      idle = 99.0
    },
    ["cpu:2"] = {
      sys = 0.5,
      usr = 0.5,
      idle = 99.0
    },
    ["sensor:1"] = {
      temp = 85.0,
      pressure = 1,
      sunlight = 55.2
    },
    ["sensor:2"] = {
      temp = 85.0 + incr,
      pressure = 1,
      sunlight = 55.2
    }
  },nil
end

function format.pack(data)
  return data
end

return format
