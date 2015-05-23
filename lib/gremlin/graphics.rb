module Gremlin
  class Graphics < `Phaser.Graphics`
    def destroy!; `#{self}.destroy()`; end
  end
end
