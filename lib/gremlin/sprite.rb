module Gremlin
  class Sprite < `Phaser.Sprite`
    def destroy!; `#{self}.destroy()`; end
    def width; `#{self}.width`; end
    def height; `#{self}.height`; end
    def image_key=(value); `#{self}.loadTexture(#{value})`; end
  end
end
