module Gremlin
  class Text < `Phaser.Text`
    attr_accessor :position
    def text; `#{self}.text`; end
    def text=(value); `#{self}.text = #{value}`; end
    def bring_to_top; `#{@parent}.bringToTop(#{self})`; end
    def width; `#{self}.width`; end
    def destroy!; `#{self}.destroy()`; end
  end
end
