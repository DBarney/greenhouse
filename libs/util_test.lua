local util = require('util')
local hrtime = require('uv').hrtime

require('tap')(function (test)

  test("test getTime", function()
    local time = util.getTime('now')
    assert(time ~= nil,"now should get a result")

    local time = util.getTime('1s')
    assert(math.floor((hrtime() - time)/1000000000) == 1,"1s should get a result")

    local time = util.getTime('2s')
    assert(math.floor((hrtime() - time)/1000000000) == 2,"2s should get a result")

    local time = util.getTime('2m')
    assert(math.floor((hrtime() - time)/(1000000000)) == 60*2,"2s should get a result")

    local time = util.getTime('2h')
    assert(math.floor((hrtime() - time)/(1000000000)) == 60*60*2,"2h should get a result")

    local time = util.getTime('2d')
    assert(math.floor((hrtime() - time)/(1000000000)) == 24*60*60*2,"2d should get a result")
  end)
end)
