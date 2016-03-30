local tap = require('tap')
table.remove(args,1)
for _,file in ipairs(args) do

  file = file:sub(8,-5)
  tap(file)
  require(file)
end
tap(true)
