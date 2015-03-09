module Gremlin
  class Game < `Phaser.Game`
    RENDERERS = {
      auto: `Phaser.AUTO`,
      canvas: `Phaser.CANVAS`,
      webgl: `Phaser.WEBGL`,
      headless: `Phaser.HEADLESS`,
    }

    def self.new(options={})
      width, height = options.fetch(:size, [`undefined`, `undefined`])
      renderer = RENDERERS.fetch(options.fetch(:renderer, :auto))
      parent = options[:parent] || `undefined`
      state = options[:state] || `undefined`
      transparent = options[:transparent] || `undefined`
      antialias = options[:antialias] || `undefined`
      physics_config = options[:physics_config] || `undefined`

      `new Phaser.Game(#{width}, #{height}, #{renderer}, #{parent}, #{state}, #{transparent}, #{antialias}, #{physics_config})`
    end
  end
end
