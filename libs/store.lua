local hrtime = require('uv').hrtime
local ffi = require('ffi')
local lmmdb = require('lmmdb')
local cache = require('ffi-cache')

local jit = require('jit')
local folder = jit.os .. '-' .. jit.arch
local compare = module:action('./' .. folder ..'/libcompare.so', ffi.load)

ffi.cdef[[
int compare_clocks(const MDB_val *a, const MDB_val *b);
]]

local Env = lmmdb.Env
local transaction = lmmdb.Txn
local cursor = lmmdb.Cursor
local DB = lmmdb.DB

local storage = {}

ffi.cdef[[
typedef struct {
  long creation; // creation date
  long value;
} number_t;
]]

function storage:insert(group)
  local time = hrtime()
  local txn = assert(Env.txn_begin(self.env,nil,0))
  for key,values in pairs(group) do
    for id,value in pairs(values) do
      local type = type(value)
      if type == 'number' then
        local pair = cache.typeof["number_t"]()
        pair.creation = time
        pair.value = value
        transaction.put(txn, self.timeseries, key .. '+' .. id, pair, 0)
      else
      end
    end
  end
  assert(transaction.commit(txn))
end

function storage:fetch(pattern, limit)
  local txn = assert(Env.txn_begin(self.env,nil,0))

  local list = {}
  local cookie = assert(cursor.open(txn, self.timeseries))
  local ok, err = cursor.get(cookie, pattern, nil, cursor.MDB_SET ,nil, -1)
  if not ok then
    transaction.abort(txn)
    return {},nil
  end
  local ok, err = cursor.get(cookie, pattern, nil, cursor.MDB_FIRST_DUP ,nil, -1)
  if not ok then
    transaction.abort(txn)
    return nil, err
  end

  -- set up real limits

  while limit > 0 do
    limit = limit - 1
    local key, number =
      cursor.get(cookie, pattern, nil, cursor.MDB_GET_CURRENT, nil, 'number_t*')
    if key == false then
      transaction.abort(txn)
      return nil, number
    end

    list[#list + 1] = tonumber(number.value)
    -- I need to see if this can fail
    local ok = cursor.get(cookie, pattern, nil, cursor.MDB_NEXT_DUP, -1, -1)
    if not ok then
      break
    end
  end
  cursor.close(cookie)

  transaction.abort(txn)
  return list
end

function storage:autoComplete(pattern)
  if pattern:len() == 0 then return {} end
  local txn = assert(Env.txn_begin(self.env,nil,0))

  local list = {}
  local cookie = assert(cursor.open(txn, self.timeseries))
  local key, err = cursor.get(cookie, pattern, nil, cursor.MDB_SET_RANGE ,nil, -1)


  while key ~= true and key ~= false and key:sub(1,string.len(pattern))==pattern do
    key,err = cursor.get(cookie, pattern, nil, cursor.MDB_GET_CURRENT, nil, nil)
    list[#list + 1] = key
    -- I need to see if this can fail
    key = cursor.get(cookie, pattern, nil, cursor.MDB_NEXT_NODUP, nil, -1)

  end
  cursor.close(cookie)

  transaction.abort(txn)
  return list
end

return function(path)
  if not path then path = './greenhouse.db' end
  local new_store = {}

  new_store.env = Env.create()

  Env.set_maxdbs(new_store.env, 1) -- we only need 1 db
  Env.set_mapsize(new_store.env, 1024*1024*1024 * 10)
  Env.reader_check(new_store.env) -- make sure that no stale readers exist

  local store = assert(Env.open(new_store.env, path, Env.MDB_NOSUBDIR, tonumber('0644', 8)))

  local txn = assert(Env.txn_begin(new_store.env,nil,0))
  new_store.timeseries = assert(DB.open(txn, "timeseries", DB.MDB_CREATE + DB.MDB_DUPSORT + DB.MDB_INTEGERDUP))
  assert(DB.set_dupsort(txn,new_store.timeseries,compare.compare_clocks))
  assert(transaction.commit(txn))

  setmetatable(new_store, { __index = storage})
  return new_store
end
