require "bundler/gem_tasks"
require 'opal'

desc 'Build game to game/build.js'
task :build_game do
  Opal.append_path 'game'
  Opal.append_path 'lib'
  File.binwrite 'game/build.js', Opal::Builder.build('game').to_s
end

desc 'Run a simple HTTP server for the game'
task :server do
  sh 'cd game && python -m SimpleHTTPServer'
end
