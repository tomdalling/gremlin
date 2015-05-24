module Gremlin
  class DisplayObject < `PIXI.DisplayObject`
    attr_accessor :position, :scale, :pivot, :rotation, :alpha, :visible, :renderable
    def bring_to_top; `#{@parent}.bringToTop(#{self})`; end
  end
end
