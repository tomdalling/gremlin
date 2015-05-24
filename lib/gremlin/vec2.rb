module Gremlin
  class Vec2 < `PIXI.Point`
    attr_accessor :x, :y

    def eset!(x, y)
      self.x = x
      self.y = y
    end

    def set!(other)
      self.x = other.x
      self.y = other.y
    end

    def add!(other)
      self.x += other.x
      self.y += other.y
    end

    def eadd!(x, y)
      self.x += x
      self.y += y
    end

    def mul!(scalar)
      self.x *= scalar
      self.y *= scalar
    end

    def +(other)
      Vec2[x + other.x, y + other.y]
    end

    def *(scalar)
      Vec2[scalar*x, scalar*y]
    end

    def coerce(other)
      [self, other]
    end

    def ==(other)
      x == other.x && y == other.y
    end

    def eql?(other)
      self == other
    end

    def eeql?(x, y)
      self.x == x && self.y == y
    end

    def hash
      x.hash ^ y.hash
    end

    def dup
      self.class.new(x, y)
    end

    def distance_to(other)
      `Math.sqrt(Math.pow(#{x} - #{other.x}, 2) + Math.pow(#{y} - #{other.y}, 2))`
    end

    def lerp_to(other, fraction)
      self.class.lerp(self, other, fraction)
    end

    def to_a
      [x, y]
    end

    class << self
      def new(x, y)
        `new PIXI.Point(#{x}, #{y})`
      end

      def [](x, y)
        new(x, y)
      end

      def from_a(array)
        raise(ArgumentError) unless array.size == 2
        new(*array)
      end

      def lerp(from, to, fraction)
        case
        when fraction <= 0.0 then from
        when fraction >= 1.0 then to
        else new(Gremlin.lerp(from.x, to.x, fraction), Gremlin.lerp(from.y, to.y, fraction))
        end
      end
    end

  end
end
