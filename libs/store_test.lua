local store = require('store')
local lmmdb = require('lmmdb')
local Env = lmmdb.Env
local transaction = lmmdb.Txn
local hrtime = require('uv').hrtime

require('tap')(function (test)

  test("get id returns correct ids for searches", function()
    local store = store("./.test/test.db")
    store:insert({
      sensor = {
        tags = {foo = "bar"},
        values = {
          other = 2,
          temp = 1
        }
      },
      asdf = {
        tags = {foo = "bar"},
        values = {
          other = 2,
          temp = 1
        }
      }
    })

    local txn = assert(Env.txn_begin(store.env,nil,0))

    local ids,err = store:lookup_ids("sensor:temp",{},txn)
    p(ids)
    assert(err == nil,err)
    assert(ids.count == 1, "wrong number of ids were returned")

    local ids,err = store:lookup_ids("sensor",{sensor = "temp"},txn)
    p(ids)
    assert(err == nil,err)
    assert(ids.count == 1, "wrong number of ids were returned")

    local ids,err = store:lookup_ids("sensor",{},txn)
    p(ids)
    assert(err == nil,err)
    assert(ids.count == 2, "wrong number of ids were returned")

    local ids,err = store:lookup_ids("senso",{},txn)
    p(ids)
    assert(err == nil,err)
    assert(ids.count == 0, "wrong number of ids were returned")

    local ids,err = store:lookup_ids("sensor",{foo = "bar"},txn)
    p(ids)
    assert(err == nil,err)
    assert(ids.count == 2, "wrong number of ids were returned")

    local ids,err = store:lookup_ids("sensor:temp",{foo = "bar"},txn)
    p(ids)
    assert(err == nil,err)
    assert(ids.count == 1, "wrong number of ids were returned")

    local ids,err = store:lookup_ids("sensor:temp",{foo = "asdf"},txn)
    p(ids)
    assert(err == nil,err)
    assert(ids.count == 0, "wrong number of ids were returned")

    local id,err = store:lookup_ids("sensor:temp",{foo = "bar"},txn,true)
    p(id)
    assert(err == nil,err)
    assert(id > 0, "wrong number of ids were returned")
    transaction.abort(txn)
  end)

  test("test store", function()
    local store = store("./.test/test-1.db")
    local now = hrtime()
    store:insert({
      sensor = {
        tags = {foo = "bar"},
        values = {
          other = 2,
          temp = 1
        }
      }
    })
    local done = hrtime()
    local results, err = store:fetch("sensor", {sensor="temp",foo="bar"}, now, done, 1)
    assert(err == nil,err)
    p(results)
    assert(results.count == 1, "wrong number of timeseries were returned")
    assert(#results[1].points == 1, "wrong number of results were returned")
    assert(results[1].count == 1, "count is wrong")
    assert(results[1].min == 1, "min is wrong")
    assert(results[1].max == 1, "max is wrong")
    assert(results[1].keys.foo == "bar","foo had wrong value")
    local results, err = store:fetch("sensor", {foo="bar"}, now, done, 1)
    assert(err == nil,err)
    assert(results.count == 2, "wrong number of timeseries were returned")
    local results,err = store:fetch("sensor", {foo="asdf"}, now, done, 1)
    assert(err == nil,err)
    assert(results.count == 0, "wrong number of results were returned")

    local complete = store:autoComplete("s")
    p(complete)
    assert(#complete == 2, "wrong number of entries")
    assert(complete[1] == "sensor:other", "wrong name returned")
    assert(complete[2] == "sensor:temp", "wrong name returned")

    local complete = store:autoComplete("a")
    assert(#complete == 0, "wrong number of entries")
  end)

  test("multiple points show up in order", function()
    local store = store("./.test/test-2.db")
    local now = hrtime()
    for i=1, 10 do
      store:insert({
        sensor = {
          tags = {foo = "bar"},
          values = {
            temp = i
          }
        }
      })
      local done = hrtime()

      local results, err = store:fetch("sensor", {sensor="temp",foo="bar"}, now, done, i)
      assert(err == nil,err)
      p(results)
      assert(results.count == 1, "wrong number of timeseries were returned")
      -- assert(#results[1].points == i, "wrong number of results were returned")
      assert(results[1].min == results[1].points[1], "min is incorrect")
      assert(results[1].max == results[1].points[#results[1].points], "max is incorrect")
      assert(results[1].count == #results[1].points, "count is incorrect")
    end
  end)
end)
