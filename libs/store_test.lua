local store = require('store')

require('tap')(function (test)

  test("test store", function()
    local store = store("./.test/test-1.db")
    store:insert({
      ["sensor:1"] = {
        temp = 1
      }
    })
    local results,err = store:fetch("sensor:1+temp", 100)
    assert(err == nil,err)
    assert(#results == 1, "wrong number of results were returned")
    local results,err = store:fetch("sensor:1+asdf", 100)
    assert(err == nil,err)
    assert(#results == 0, "wrong number of results were returned")

    local complete = store:autoComplete("s")
    assert(#complete == 1, "wrong number of entries")
    assert(complete[1] == "sensor:1+temp", "wrong name returned")

    local complete = store:autoComplete("a")
    assert(#complete == 0, "wrong number of entries")
  end)

  test("multiple points show up in order", function()
    local store = store("./.test/test-2.db")
    for i=1, 10 do
      store:insert({
        ["sensor:1"] = {
          temp = i
        }
      })

      local results,err = store:fetch("sensor:1+temp", 100)
      assert(err == nil,err)
      p(results)
      for idx,value in pairs(results) do
        assert((#results - idx) + 1 == value,"numbers are out of order")
      end
      assert(#results == i, "wrong number of results were returned")
    end
  end)
end)
