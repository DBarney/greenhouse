local bundle = require('luvi').bundle
_G.p = require('pretty-print').prettyPrint


local uv = require 'uv'
local cli = require 'cli'
local bed = require 'cmd/bed'
local greenhouse = require 'cmd/greenhouse'


cli.addCommand("run",greenhouse)
cli.addCommand("bed",bed)
cli.setDefault("run")
cli.run(args)

uv.run()
