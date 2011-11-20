#!/usr/bin/env ruby
require 'plugins/thermostat/sirithermostat'
require 'plugins/testproxy/testproxy'
require 'plugins/moodle/moodle'
require 'tweaksiri'
require 'siriproxy'

PLUGINS = [Moodle]

proxy = SiriProxy.new(PLUGINS)

#that's it. :-)
