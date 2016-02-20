-- Greenhouse is the main server that receives statistical data and stores it
-- for use later

local uv = require('uv')
local start_udp = require('udp_listener')
local start_http = require('http_listener')
local store = require('store')

return function()
  start_udp(store)
  start_http(store)
end
