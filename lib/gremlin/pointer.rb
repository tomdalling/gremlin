module Gremlin
  class Pointer < `Phaser.Pointer`
    def id; `#{self}.id`; end
    def position; `#{self}.position`; end
    def position_down; `#{self}.positionDown`; end
    def position_up; `#{self}.positionUp`; end
  end
end
