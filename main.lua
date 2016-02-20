local bundle = require('luvi').bundle
_G.p = require('pretty-print').prettyPrint


local uv = require 'uv'
local cli = require 'cli'
local bed = require 'cmd/bed'
local glaze = require 'cmd/glaze'
local greenhouse = require 'cmd/greenhouse'


cli.addCommand("run",greenhouse)
cli.addCommand("bed",bed)
cli.addCommand("glaze",glaze)
cli.setDefault("fun")
cli.run(args)

uv.run()
