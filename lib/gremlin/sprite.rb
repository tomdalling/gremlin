module Gremlin
  class Sprite < `Phaser.Sprite`
    def width; `#{self}.width`; end
    def height; `#{self}.height`; end
  end
end
