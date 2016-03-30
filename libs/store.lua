local hrtime = require('uv').hrtime
local null = require('json').null
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
  long long creation; // creation date
  double value;
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

function storage:fetch(pattern, start, stop, steps)
  local step = math.floor((stop - start)/ steps)
  local txn = assert(Env.txn_begin(self.env,nil,0))
  local start_key = cache.typeof["number_t"]()
  start_key.creation = start
  local stop_key = cache.typeof["number_t"]()
  stop_key.creation = stop
  local now = cache.typeof["number_t"]()
  now.creation = hrtime()

  local cookie = assert(cursor.open(txn, self.timeseries))
  local key, value = cursor.get(cookie, pattern, start_key, cursor.MDB_GET_BOTH_RANGE ,nil, 'number_t*')
  if key ~= pattern then
    transaction.abort(txn)
    return {points = {}, count = 0},nil
  end

  local buckets = {}
  while value.creation < stop do
    key, value =
      cursor.get(cookie, pattern, nil, cursor.MDB_GET_CURRENT, nil, 'number_t*')
    local idx = math.floor(tonumber((value.creation - start) / step) + 1)
    local bucket = buckets[idx]
    if bucket == nil then
      bucket = {}
      buckets[idx] = bucket
    end
    bucket[#bucket + 1] = value.value

    local ok = cursor.get(cookie, nil, nil, cursor.MDB_NEXT_DUP, -1, -1)
    if not ok then
      break
    end
  end

  local min
  local max
  local count = 0
  local prev = 0
  local results = {}
  for idx, bucket in pairs(buckets) do
    local value = 0

    for _, num in pairs(bucket) do
      value = value + num
    end
    value = tonumber(value)/#bucket
    results[idx] = value
    while prev < idx do
      prev = prev + 1
      if results[prev] == nil then
        results[prev] = null
      end
      count = count + 1
    end

    min = math.min(value, min or value)
    max = math.max(value, max or value)
  end
  cursor.close(cookie)

  transaction.abort(txn)
  return {points = results, min = min, max = max, count = count}
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

function storage:info()
  local info = {}
  local stat = Env.stat(self.env)
  for _, key in pairs({'ms_psize','ms_depth','ms_branch_pages','ms_leaf_pages','ms_overflow_pages','ms_entries'}) do
    info[key] = tonumber(stat[key])
  end
  return info
end

return function(path)
  if not path then path = './greenhouse.db' end
  local new_store = {}

  new_store.env = Env.create()

  Env.set_maxdbs(new_store.env, 1) -- we only need 1 db
  Env.set_mapsize(new_store.env, 1024*1024*1024 * 10)
  Env.reader_check(new_store.env) -- make sure that no stale readers exist

  local store = assert(Env.open(new_store.env, path, Env.MDB_NOSUBDIR + Env.MDB_NOSYNC, tonumber('0644', 8)))

  local txn = assert(Env.txn_begin(new_store.env,nil,0))
  new_store.timeseries = assert(DB.open(txn, "timeseries", DB.MDB_CREATE + DB.MDB_DUPSORT + DB.MDB_INTEGERDUP + DB.MDB_DUPFIXED))
  assert(DB.set_dupsort(txn,new_store.timeseries,compare.compare_clocks))
  assert(transaction.commit(txn))

  setmetatable(new_store, { __index = storage})
  return new_store
end
