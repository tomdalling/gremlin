module Gremlin
  class Sprite < `Phaser.Sprite`
    def destroy!; `#{self}.destroy()`; end
    def width; `#{self}.width`; end
    def height; `#{self}.height`; end
    def size; Vec2[width, height]; end
    def image_key=(value); `#{self}.loadTexture(#{value})`; end

    # TODO: animation API needs refactoring
    def add_animation(*args);
      `#{self}.animations.add.apply(#{self}.animations, #{args})`
    end
    def play_animation(*args);
      `#{self}.animations.play.apply(#{self}.animations, #{args})`
    end
  end
end
