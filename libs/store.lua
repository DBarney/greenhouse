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

function storage:insert(groups)
  local time = hrtime()
  local txn = assert(Env.txn_begin(self.env,nil,0))
  for key,object in pairs(groups) do
    for name,value in pairs(object.values) do
      local timeseries_name = key .. ":" .. name
      -- lookup time series ids
      local timeseries_id, err = self:lookup_ids(timeseries_name, object.tags, txn, true)
      if err then
        timeseries_id = hrtime()
        p(txn, self.names, timeseries_name, timeseries_id, 0)
        assert(transaction.put(txn, self.names, timeseries_name, timeseries_id, 0))
        for tag, value in pairs(object.tags) do
          local tag_key = timeseries_id .. ":" .. tag
          assert(transaction.put(txn, self.indexes, tag_key, value, 0))
        end
      end
      local type = type(value)
      if type == 'number' then
        local pair = cache.typeof["number_t"]()
        pair.creation = time
        pair.value = value
        assert(transaction.put(txn, self.timeseries, timeseries_id, pair, 0))
      else
      end
    end
  end
  assert(transaction.commit(txn))
end

function storage:fetch(name, keys, start, stop, steps)
  local step = math.floor((stop - start)/ steps)

  local start_key = cache.typeof["number_t"]()
  start_key.creation = start
  local stop_key = cache.typeof["number_t"]()
  stop_key.creation = stop
  local now = cache.typeof["number_t"]()
  now.creation = hrtime()

  local collections = {count = 0}
  local txn = assert(Env.txn_begin(self.env,nil,transaction.MDB_RDONLY))
  local matches = self:lookup_ids(name,keys,txn)
  local cookie = assert(cursor.open(txn, self.timeseries))
  for id,info in pairs(matches.ids) do
    local key, value = cursor.get(cookie, id, start_key, cursor.MDB_GET_BOTH_RANGE, "long long*", 'number_t*')
    assert(key[0] == id)
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
    collections.count = collections.count + 1
    collections[collections.count] = {name = info.name, tags = info.tags, points = results, min = min, max = max, count = count}
  end
  cursor.close(cookie)

  transaction.abort(txn)
  return collections
end

function storage:lookup_ids(name, keys, txn, exact)
  local old_name = name
  if not name:match(":") then
    name = name  .. ":" .. (keys[name] or "")
  end
  keys[old_name] = nil
  local cookie = assert(cursor.open(txn, self.names))
  local found, err = cursor.get(cookie, name, nil, cursor.MDB_SET_RANGE , nil, -1)

  local count = 0
  local indexes = {}
  while found and found:sub(1,string.len(name))==name do
    if exact and name:len() ~= found:len() then
      break
    end
    local key, id =
      cursor.get(cookie, name, nil, cursor.MDB_GET_CURRENT, nil, 'long long*')
    indexes[tonumber(id[0])] = {name = key, tags = {}}
    count = count + 1

    found = cursor.get(cookie, nil, nil, cursor.MDB_NEXT_DUP, nil, -1)
    if not found then
      found = cursor.get(cookie, nil, nil, cursor.MDB_NEXT, nil, -1)
    end
  end
  cursor.close(cookie)


  local cookie = assert(cursor.open(txn, self.indexes))
  for key,value in pairs(keys) do
    local remove = {}
    for id,info in pairs(indexes) do
      local both = id .. ":" .. key
      local test_key, test_value = cursor.get(cookie, both, value, cursor.MDB_GET_BOTH ,nil, nil)
      if not (test_key == both and test_value == value) then
        remove[#remove + 1] = id
      end
    end
    for _,id in pairs(remove) do
      indexes[id] = nil
      count = count - 1
    end
  end

  if not exact then
    for id, info in pairs(indexes) do
      local matcher = id .. ":"
      local found,_ = cursor.get(cookie, matcher, nil, cursor.MDB_SET_RANGE, -1, nil)

      while found do
        local key, value =
          cursor.get(cookie, name, nil, cursor.MDB_GET_CURRENT, nil, nil)
        local name = key:match('[0-9]+:(.+)')
        info.tags[name] = value
        found = cursor.get(cookie, nil, nil, cursor.MDB_NEXT, nil, -1)
      end
    end
  end
  cursor.close(cookie)

  if exact then
    if count == 1 then
      for id in pairs(indexes) do
        return id
      end
    else
      return nil, "not an exact match"
    end
  else
    return {ids = indexes, count = count}
  end
end

function storage:autoComplete(pattern)
  if pattern:len() == 0 then return {} end
  local txn = assert(Env.txn_begin(self.env,nil,0))

  local list = {}
  local cookie = assert(cursor.open(txn, self.names))
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

  Env.set_maxdbs(new_store.env, 3) -- we only need 1 db
  Env.set_mapsize(new_store.env, 1024*1024*1024 * 10)
  Env.reader_check(new_store.env) -- make sure that no stale readers exist

  local store = assert(Env.open(new_store.env, path, Env.MDB_NOSUBDIR + Env.MDB_MAPASYNC, tonumber('0644', 8)))

  local txn = assert(Env.txn_begin(new_store.env,nil,0))
  new_store.timeseries = assert(DB.open(txn, "timeseries", DB.MDB_CREATE + DB.MDB_DUPSORT + DB.MDB_INTEGERDUP + DB.MDB_DUPFIXED + DB.MDB_INTEGERKEY))
  new_store.names = assert(DB.open(txn, "names", DB.MDB_CREATE + DB.MDB_DUPSORT + DB.MDB_INTEGERDUP + DB.MDB_DUPFIXED))
  new_store.indexes = assert(DB.open(txn, "indexes", DB.MDB_CREATE + DB.MDB_DUPSORT))
  assert(DB.set_dupsort(txn,new_store.timeseries,compare.compare_clocks))
  assert(transaction.commit(txn))

  setmetatable(new_store, { __index = storage})
  return new_store
end
