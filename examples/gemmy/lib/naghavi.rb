require 'gremlin'

module Naghavi
  module Color
    #TODO: proper colors here
    WHITE = 'white'
    YELLOW = 'yellow'
    RED = 'red'
  end

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

  module DefStruct
    def self.new(&defaults_block)
      defaults = defaults_block.call
      klass = Struct.new(*defaults.keys) do
        def initialize(attrs={})
          defaults = self.class.const_get(:DEFAULTS_BLOCK).call
          defaults.merge!(attrs).each do |k, v|
            self[k] = v
          end
        end

        def self.reopen(&block)
          self.class_exec(&block)
          self
        end
      end

      klass.const_set(:DEFAULTS_BLOCK, defaults_block)
      klass
    end
  end

  def self.vlerp(from, to, fraction)
    if fraction <= 0.0
      from
    elsif fraction >= 1.0
      to
    else
      [lerp(from.x, to.x, fraction),
       lerp(from.y, to.y, fraction)]
    end
  end

  def self.lerp(start, final, progress)
    if progress <= 0.0
      start
    elsif progress >= 1.0
      final
    else
      start + progress*(final - start)
    end
  end

  def self.distance(x1, y1, x2, y2)
    `Math.sqrt(Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2))`
  end
end

class Array
  def vadd(vec)
    self.dup.vadd!(vec)
  end

  def vadd!(vec)
    (0...vec.size).each do |idx|
      self[idx] = self[idx] + vec[idx]
    end
    self
  end

  def vmul(scalar)
    self.dup.vmul!(scalar)
  end

  def vmul!(scalar)
    self.map! do |val|
      scalar * val
    end
    self
  end

  def vset!(vec)
    (0...vec.size).each do |idx|
      self[idx] = vec[idx]
    end
    self
  end

  def vinterp_to(vec, factor)
  end

  def x
    self[0]
  end

  def x=(x)
    self[0] = x
  end

  def y
    self[1]
  end

  def y=(y)
    self[1] = y
  end
end
