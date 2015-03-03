require 'opal'
require "gremlin/version"

module Gremlin
  class Game
    attr_accessor :context
    def draw(image, options={})
      context.draw_image(image, options)
    end
  end

  def self.run!(game, parent_element=nil)
    %x{
      var renderer = PIXI.autoDetectRenderer(400, 300);
      document.addEventListener('DOMContentLoaded', function () {
        var container = #{parent_element || `document.body`};
        container.appendChild(renderer.view);
        #{Gremlin::Context.new(game, `renderer`).run!} 
      });
    }
  end

  class Context
    def initialize(game, renderer)
      @game = game
      @renderer = renderer
      @stage = nil

      game.context = self
    end

    def run!
      %x{
        function animate() {
          requestAnimFrame(animate);
          #{update_and_render}
        }
        requestAnimFrame(animate);
      }
    end

    def draw_image(image, options)
      x, y = options.fetch(:at, [0,0])
      %x{
        var sprite = new PIXI.Sprite(#{image}.texture);
        sprite.position.x = #{x};
        sprite.position.y = #{y};
        #{@stage}.addChild(sprite);
      }
    end

    private

      def update_and_render
        @game.update(1/60)

        #TODO: pretty inefficient. should reuse the stage and sprites
        @stage = `new PIXI.Stage(0x66FF99)`
        @game.render
        %x{#{@renderer}.render(#{@stage})}
      end
  end

  class Image
    def initialize(path)
      @texture = `PIXI.Texture.fromImage(#{path})`
    end
  end
end
