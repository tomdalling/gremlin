module Gremlin
  class DisplayObject < `PIXI.DisplayObject`
    attr_accessor :position, :scale, :pivot, :rotation, :alpha, :visible, :renderable
  end

  class Point < `PIXI.Point`
    attr_accessor :x, :y

    def self.new(x, y)
      `new PIXI.Point(#{x}, #{y})`
    end

    def self.[](x, y)
      new(x, y)
    end

    def set!(x, y)
      self.x = x
      self.y = y
    end

    def dup
      self.class.new(x, y)
    end
  end
end
