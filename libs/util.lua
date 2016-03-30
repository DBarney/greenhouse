local hrtime = require('uv').hrtime
local util = {}


function util.getTime(time)
  local now = hrtime()
  if time == 'now' then
    return now
  else
    local count, unit = (time:lower()):match('([0-9]+)([smhd])')
    count = tonumber(count)
    if unit == 's' then
      return now - 1000000000*count
    elseif unit == 'm' then
      return now - 60*1000000000*count
    elseif unit == 'h' then
      return now - 60*60*1000000000*count
    elseif unit == 'd' then
      return now - 24*60*60*1000000000*count
    end
  end
end

return util
