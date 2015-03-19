require "bundler/gem_tasks"
require 'opal'

desc 'Build an example game'
task :build_example, :name do |task, args|
  name = args[:name] || 'gemmy'

  Opal.append_path "examples/#{name}/lib"
  Opal.append_path 'lib'
  File.binwrite "examples/#{name}/dist/#{name}.js", Opal::Builder.build(name).to_s
end

desc 'Run a simple HTTP server for an example game'
task :serve_example, :name do |task, args|
  name = args[:name] || 'gemmy'
  sh "cd examples/#{name}/dist && python -m SimpleHTTPServer"
end

