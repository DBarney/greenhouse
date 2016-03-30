local getTime = require('util').getTime
local hrtime = require('uv').hrtime
local weblit = require('weblit-app')
local json = require('json')
local graph = require('graph')


local function getResults(store, string)
  local query, _, err = json.decode(string)
  if err ~= nil then
    return {error = 'unable to parse json'}
  end
  for a, key in pairs({"pattern","start","stop","step"}) do
    if query[key] == nil then
      return {error = 'missing '..key}
    end
  end
  local start = getTime(query.start)
  local stop = getTime(query.stop)
  if stop < start then
    return {error = 'start should be before stop'}
  end
  return store:fetch(query.pattern,start,stop,query.step)
end


return function(store, host, port)
  weblit
  .bind({host = host, port = port})

  .use(weblit.autoHeaders)

  .route({ path = "/complete/:word"}, function (req, res)
    p(req)
    local results = store:autoComplete(req.params.word)
    res.body = json.encode(results)
    res.headers["content-length"] = #res.body
    res.code = 200
  end)

  .route({path = "/graph"}, function (req, res)
    local results = {}
    for name, query in pairs(req.query) do
      result, err = getResults(store, query)
      if err ~= nil then
        res.code = 500
        res.body = err
        return
      end
      results[name] = result
    end
    res.body = graph.render(results)
    res.headers["content-length"] = #res.body
    res.headers["content-type"] = "image/svg+xml"
    res.code = 200
  end)

  .route({ path = "/query"}, function (req, res)
    local results = {}
    for name, query in pairs(req.query) do
      result, err = getResults(store, query)
      if err ~= nil then
        res.code = 500
        res.body = err
        return
      end
      results[name] = result
    end
    res.body = json.encode(results)
    res.headers["content-length"] = #res.body
    res.code = 200
  end)

  .start()
end
