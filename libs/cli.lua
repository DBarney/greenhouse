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
  if name == nil then
    error("name cannot be nil")
  end
  if fun == nil then
    error("fun cannot be nil: "..name)
  end
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
    if value:byte(1) == 45 then
      flags[#flags + 1] = value:sub(2)
    else
      if command == nil then
        command = value
      else
        args[#args + 1] = value
      end
    end
  end

  result = cli.commands[command]
  if result == nil then
    result = cli.commands[default]
    table.insert(args,1,command)
  end
  if result == nil then
    error("unknown command ", command, default)
  end
  result.exec(args,flags)
end

return cli
