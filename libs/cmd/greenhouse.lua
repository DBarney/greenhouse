-- Greenhouse is the main server that receives statistical data and stores it
-- for use later

local uv = require('uv')
local start_udp = require('udp_listener')
local start_http = require('http_listener')

return function()
  local store = require('store')('./greenhouse.db')
  start_udp(store)
  start_http(store,"127.0.0.1",8080)

  -- record stats about the greenhouse process
  local timer = uv.new_timer()
  uv.timer_start(timer, 10000, 10000, function()
    local stats = uv.getrusage()
    for _, time in pairs({'stime','utime'}) do
      local times = stats[time]
      stats[time] = times.sec*1000000 + times.usec
    end

    local s,m,l = uv.loadavg()
    stats.load1 = s
    stats.load5 = m
    stats.load15 = l

    stats.memory_total = uv.get_total_memory()
    stats.memory_free = uv.get_free_memory()
    for key,value in pairs(store:info()) do
      stats[key] = value
    end

    store:insert({greenhouse = {values = stats, tags = {host = "this.machine"}}})
  end)
end
