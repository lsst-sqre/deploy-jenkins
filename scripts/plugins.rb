#!/usr/bin/env ruby
#
require 'yaml'
foo = YAML.load_file('plugins.yaml')

bar = foo['jenkins::plugin_hash']


plugins = []
bar.each { |k,v|
  plugins << "#{k}:#{v['version']}"
}

output = { 'installPlugins' => plugins }

puts output.to_yaml
