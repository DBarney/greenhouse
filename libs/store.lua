local hrtime = require('uv').hrtime
local ffi = require('ffi')
local lmmdb = require('lmmdb')
local cache = require('ffi-cache')

local Env = lmmdb.Env
local transaction = lmmdb.Txn
local cursor = lmmdb.Cursor
local DB = lmmdb.DB
local enviroment = Env.create()

Env.set_maxdbs(enviroment, 5) -- we only need 5 dbs
Env.set_mapsize(enviroment, 1024*1024*1024 * 10)
Env.reader_check(enviroment) -- make sure that no stale readers exist

local store = assert(Env.open(enviroment, './', 0, tonumber('0644', 8)))

local txn = assert(Env.txn_begin(enviroment,nil,0))
local timeseries = assert(DB.open(txn, "timeseries", DB.MDB_CREATE + DB.MDB_DUPSORT + DB.MDB_INTEGERDUP))
assert(transaction.commit(txn))

local storage = {
  db = store
}

ffi.cdef[[
typedef struct {
  long creation; // creation date
  long value;
} number_t;
]]

function storage:insert(group)
  local time = hrtime()
  local txn = assert(Env.txn_begin(enviroment,nil,0))
  for key,values in pairs(group) do
    for id,value in pairs(values) do
      local type = type(value)
      if type == 'number' then
        local pair = cache.typeof["number_t"]()
        pair.creation = time
        pair.value = value
        p('inserting',key .. '+' .. id)
        transaction.put(txn, timeseries, key .. '+' .. id, pair, 0)
      else
      end
    end
  end
  assert(transaction.commit(txn))
end

function storage:fetch(pattern, limit)
  local txn = assert(Env.txn_begin(enviroment,nil,0))

  local list = {}
  local cookie = assert(cursor.open(txn, timeseries))
  p('looking up',pattern,limit)
  local ok, err = cursor.get(cookie, pattern, nil, cursor.MDB_SET ,nil, -1)
  if not ok then
    transaction.abort(txn)
    error(err)
  end
  p('looking up',pattern,limit)
  local ok, err = cursor.get(cookie, pattern, nil, cursor.MDB_LAST_DUP ,nil, -1)
  if not ok then
    transaction.abort(txn)
    error(err)
  end

  -- skip ahead a few?

  while limit > 0 do
    limit = limit - 1
    local key, number =
      cursor.get(cookie, pattern, nil, cursor.MDB_GET_CURRENT, nil, 'number_t*')
    if key == false then
      transaction.abort(txn)
      error(number)
    end
    -- if key ~= pattern then
    --   p("didn't match",key,pattern,number)
    --   break
    -- end
    p(key)

    list[#list + 1] = tonumber(number.value)
    -- I need to see if this can fail
    local ok = cursor.get(cookie, pattern, nil, cursor.MDB_PREV_DUP, -1, -1)
    if not ok then
      break
    end
  end
  cursor.close(cookie)

  transaction.abort(txn)
  return list
end

return storage
