local store = require('store')
local hrtime = require('uv').hrtime

require('tap')(function (test)

  test("test store", function()
    local store = store("./.test/test-1.db")
    local now = hrtime()
    store:insert({
      ["sensor:1"] = {
        temp = 1
      }
    })
    local done = hrtime()
    local results,err = store:fetch("sensor:1+temp", now, done, 1)
    assert(err == nil,err)
    assert(#results.points == 1, "wrong number of results were returned")
    assert(results.count == 1, "count is wrong")
    assert(results.min == 1, "min is wrong")
    assert(results.max == 1, "max is wrong")
    local results,err = store:fetch("sensor:1+asdf", now, done, 1)
    assert(err == nil,err)
    assert(#results.points == 0, "wrong number of results were returned")

    local complete = store:autoComplete("s")
    assert(#complete == 1, "wrong number of entries")
    assert(complete[1] == "sensor:1+temp", "wrong name returned")

    local complete = store:autoComplete("a")
    assert(#complete == 0, "wrong number of entries")
  end)

  test("multiple points show up in order", function()
    local store = store("./.test/test-2.db")
    local now = hrtime()
    for i=1, 10 do
      store:insert({
        ["sensor:1"] = {
          temp = i
        }
      })
      local done = hrtime()

      local results,err = store:fetch("sensor:1+temp", now, done, i)
      assert(err == nil,err)
      -- assert(#results.points == i, "wrong number of results were returned")
      assert(results.min == results.points[1], "min is incorrect")
      assert(results.max == results.points[#results.points], "max is incorrect")
      assert(results.count == #results.points, "count is incorrect")
    end
  end)
end)
