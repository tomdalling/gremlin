require 'gremlin'

module Naghavi
  class Scene
    attr_accessor :window
    alias :w :window

    def startup; end
    def shutdown; end
    def update; end
    def draw; end
    def button_down(button); end
    def button_up(button); end
    def needs_redraw?; true; end
    def needs_cursor?; true; end
  end

  class Window < Gremlin::State
    def initialize(scene, assets)
      super()
      @initial_scene = scene
      @assets = assets
    end

    def assets
      @assets
    end

    def create
      super
      transition_to_scene(@initial_scene)
    end

    def key_down(button)
      maybe_transition { @scene.button_down(button) }
    end

    def key_up(button)
      maybe_transition { @scene.button_up(button) }
    end

    def update
      maybe_transition { @scene.update }
    end

    def draw
      @scene.draw
    end

    private

      def maybe_transition
        transition_to_scene(yield)
      end

      def transition_to_scene(scene)
        while scene && !native?(scene) && scene.is_a?(Scene)
          if @scene
            @scene.window = nil
            @scene.shutdown
          end

          # clear world, but don't clear cache
          `#{self}.game.world.shutdown()`

          @scene = scene
          @scene.window = self
          scene = @scene.startup
        end
      end
  end

end
