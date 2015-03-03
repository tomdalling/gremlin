require 'gremlin'

MOVE_SPEED = 100

class Game < Gremlin::Game
  def initialize
    @player = Gremlin::Image.new('player.png')
    @x = 0
  end

  def update(delta_time)
    @x += delta_time * MOVE_SPEED
  end

  def render
    draw(@player, at: [@x, 50])
  end
end

Gremlin.run!(Game.new)
