--[[
The cli module exposes a small api for configuring a cli driven app
]]

local cli = {}
cli.commands = {}
local default = nil
function cli.setDefault(name)
  default = name
end

function cli.addCommand(name,fun,config)
  if cli.commands[name] ~= nil then
    error("command " + name +" is already defined")
  end
  cli.commands[name] = {
    exec = fun,
    config = config or {}
  }
end

function cli.run(options)
  local flags = {}
  local command = nil
  local args = {}
  for _,value in ipairs(options) do
    if value[0] == '-' then
      args.push(flags)
    else
      if command == nil then
        command = value
      else
        args.push(value)
      end
    end
  end
  p(command,flags,args)

  result = cli.commands[command] or cli.commands[default]
  if result == nil then
    error("unknown command ", command)
  end
  result.exec(args,flags)
end

return cli
