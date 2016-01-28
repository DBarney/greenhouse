local bundle = require('luvi').bundle
_G.p = require('pretty-print').prettyPrint


local uv = require 'uv'
local cli = require 'libs/cli'


cli.addCommand("run",function() end,{})
cli.setDefault("fun")

cli.run(args)

uv.run()
