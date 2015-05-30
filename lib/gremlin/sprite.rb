module Gremlin
  class Sprite < `Phaser.Sprite`
    def destroy!; `#{self}.destroy()`; end
    def width; `#{self}.width`; end
    def height; `#{self}.height`; end
    def size; Vec2[width, height]; end
    def image_key=(value); `#{self}.loadTexture(#{value})`; end

    # TODO: animation API needs refactoring
    def play_animation(name)
      `#{self}.animations.play(#{name})`
    end
  end
end
