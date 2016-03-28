local weblit = require('weblit-app')
local json = require('json')

local function getResults(store, string)
  local query, _, err = json.decode(string)
  if err ~= nil then
    return {error = 'unable to parse json'}
  end
  for a, key in pairs({"pattern","limit"}) do
    if query[key] == nil then
      return {error = 'missing '..key}
    end
  end
  return store:fetch(query.pattern,query.limit)
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
