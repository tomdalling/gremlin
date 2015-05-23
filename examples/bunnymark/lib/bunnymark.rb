require 'gremlin'

GRAVITY = 200 # pixels/sec^2

Bunny = Struct.new(:sprite, :velocity)

class MyState < Gremlin::State
  def assets
    {
      image: [:bunny]
    }
  end

  def create
    super
    @bunnies = []
    @fps = add_text('', fill: :white)
    @fps.position.set!(20, 20)
    enabled_advanced_timing!
  end

  def update(*args)
    dt = delta_time
    gs = game_size
    @bunnies.each do |t|
      # get some vars
      vel = t.velocity
      pos = t.sprite.position
      size = Gremlin::Point[t.sprite.width, t.sprite.height]

      # apply gravity and velocity
      vel.y += dt*GRAVITY
      pos.x += dt*vel.x
      pos.y += dt*vel.y

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
        t.velocity = Gremlin::Point[rand(-200..200), 0]
        t.sprite = add_sprite(:bunny)
        t.sprite.position.x = rand(800)
        @bunnies << t
      end
      @fps.bring_to_top
    end

    @fps.text = "FPS: #{average_fps}, BUNNIES: #{@bunnies.size}"
  end
end

state = MyState.new
game = Gremlin::Game.new(size: [800, 300], state: state)

