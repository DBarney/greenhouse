require('luvi')
_G.require = require('require')('test') -- bootstrap the require
local tap = require('tap')
for _,file in ipairs(args) do
  file = file:sub(3,-5)
  tap(file)
  require(file)
end
tap(true)
require('uv').run()
