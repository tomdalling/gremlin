require 'opal'
require 'native'
require 'gremlin/version'
require 'gremlin/vec2'
require 'gremlin/display_object'
require 'gremlin/keyboard'
require 'gremlin/game'
require 'gremlin/sprite'
require 'gremlin/text'
require 'gremlin/graphics'

module Gremlin

  def self.lerp(from, to, fraction)
    case
    when fraction <= 0.0 then from
    when fraction >= 1.0 then to
    else from + fraction*(to - from)
    end
  end

  def self.run_game(game_class, options)
    state = game_class.new
    state.patch_phaser_methods!

    width = options.fetch(:width, `undefined`)
    height = options.fetch(:height, `undefined`)
    renderer = RENDERERS.fetch(options.fetch(:renderer, :auto))
    parent = options[:parent] || `undefined`
    transparent = options[:transparent] || `undefined`
    antialias = options[:antialias] || `undefined`
    physics_config = options[:physics_config] || `undefined`

    `new Phaser.Game(#{width}, #{height}, #{renderer}, #{parent}, #{state}, #{transparent}, #{antialias}, #{physics_config})`
  end

  RENDERERS = {
    auto: `Phaser.AUTO`,
    canvas: `Phaser.CANVAS`,
    webgl: `Phaser.WEBGL`,
    headless: `Phaser.HEADLESS`,
  }
end
