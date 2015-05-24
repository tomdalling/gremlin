require 'gremlin'

class Bunnymark < Gremlin::Game
  GRAVITY = 200 # pixels/sec^2
  Bunny = Struct.new(:sprite, :velocity)

  def assets
    { image: [:bunny] }
  end

  def create
    enabled_advanced_timing!
    @bunnies = []
    @fps = add_text('', fill: :white)
    @fps.position.eset!(20, 20)
  end

  def update
    dt = delta_time
    gs = canvas_size
    @bunnies.each do |t|
      # get some vars
      vel = t.velocity
      pos = t.sprite.position
      size = t.sprite.size

      # apply gravity and velocity
      vel.eadd!(0, dt*GRAVITY)
      pos.add!(dt*vel)

      # bounce off floor
      max_y = pos.y + size.y
      if max_y > gs.y
        pos.y = gs.y - (max_y - gs.y) - size.y
        vel.y = -(vel.y)
      end

      # bounce off left
      if pos.x < 0
        pos.x = -(pos.x)
        vel.x = -(vel.x)
      end

      # bounce off right
      max_x = pos.x + size.x
      if max_x > gs.x
        pos.x = gs.x - size.x - (max_x - gs.x)
        vel.x = -(vel.x)
      end
    end

    if key_down?(Gremlin::Keyboard::KEY_SPACEBAR)
      5.times do
        t = Bunny.new
        t.velocity = Gremlin::Vec2[rand(-200..200), 0]
        t.sprite = add_sprite(:bunny)
        t.sprite.position.x = rand(800)
        @bunnies << t
      end
      @fps.bring_to_top
    end

    @fps.text = "FPS: #{average_fps}, BUNNIES: #{@bunnies.size}"
  end
end

Gremlin.run_game(
  Bunnymark,
  width: 800,
  height: 300,
  smooth_sprites: false
)

