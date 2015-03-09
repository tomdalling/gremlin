module Gremlin
  class Text < `Phaser.Text`
    def bring_to_top
      `#{@parent}.bringToTop(#{self})`
    end

    def text; `#{self}.text`; end
    def text=(value); `#{self}.text = #{value}`; end
  end
end
