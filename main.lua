local bundle = require('luvi').bundle
_G.p = require('pretty-print').prettyPrint


local uv = require 'uv'
local cli = require 'cli'
local bed = require 'cmd/bed'
local greenhouse = require 'cmd/greenhouse'
local test = require 'cmd/test'


cli.addCommand("run",greenhouse)
cli.addCommand("bed",bed)
cli.addCommand("test",test)
cli.setDefault("run")
cli.run(args)

uv.run()
