local graph = {}

function graph.render(groups)
  local graph = {""}
  local min = nil
  local max = nil
  local count = 0
  for key,values in pairs(groups) do
    if values.count > count then
      count = values.count
    end

    min = math.min(values.min,min or values.min)
    max = math.max(values.max,max or values.max)
    local data = {}
    local action = "M"
    for idx, point in pairs(values.points) do
      data[#data + 1] = action .. idx .. " " .. point
      action = "L"
    end
    graph[#graph + 1] =
    '<path d="' .. table.concat(data," ") .. '" stroke-width="1" stroke="black" fill="none"></path>'
  end
  graph[1] = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 '.. min ..' '.. count ..' ' .. max ..'" preserveAspectRatio="none">'
  graph[#graph + 1] = '</svg>'
  return table.concat(graph)
end

return graph
