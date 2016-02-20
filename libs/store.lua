local store = {
  storage = {}
}

function store:insert(data)
  p('inserting', data)
  time = data.time
  for key,values in data.points do
    timeseries = self.storage[key]
    if timeseries == nil then
      timeseries = {}
      self.storage[key] =timeseries
    end
    for _,value in values do
      timeseries[time] = value
    end
  end
end

function store:fetch()
  return {
    temperature = {
      sensor1 = {1,2,1,2,1,2,1,2,1,2}
    }
  }
end

return store
