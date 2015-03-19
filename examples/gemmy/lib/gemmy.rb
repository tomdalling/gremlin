require 'naghavi'
include Gremlin::Keyboard

NUM_LEVELS = 9

MOVE_INTERVAL = 0.1
GRID_SIZE = 64
CELL_TYPES_BY_CHAR = {
  'x' => :wall,
  ' ' => :floor,
  'p' => :player,
  'g' => :goal,
  'e' => :enemy,
  's' => :shooter,
  'd' => :dirtball,
  't' => :teleporter,
}

PI = `Math.PI`

ORIENTATION_ROTATIONS = {
  north: 0,
  east: PI/2,
  south: PI,
  west: PI*1.5,
}

IMAGES_BY_KEY = {
  player: ['ant_01.png', 'ant_02.png', 'ant_03.png'],
  chaser: ['enemy_ant_01.png', 'enemy_ant_02.png', 'enemy_ant_03.png'],
  floor: ['floor.png', 'floor_cracked_01.png', 'floor_cracked_02.png', 'floor_cracked_03.png'],
  wall: ['wall01.png', 'wall02.png', 'wall03.png', 'wall04.png'],
  gems: ['blue_gem.png', 'red_gem.png'],
  goal: ['leaf_1.png', 'leaf_2.png', 'leaf_3.png'],
  dirtball: ['dirt_ball.png'],
  shooter: ['enemy_1.png', 'enemy_2.png', 'enemy_3.png', 'enemy_4.png', 'enemy_5.png'],
  bullet: ['bullen.png'],
  teleporter: ['Swirl 1.png', 'Swirl 2.png', 'Swirl 3.png', 'Swirl 4.png'],
}

Animation = Naghavi::DefStruct.new {{
  image_key: nil,
  current_frame: 0,
  secs_per_frame: 0.3,
  secs_elapsed_this_frame: 0,
}}

Entity = Naghavi::DefStruct.new {{
  sprite: nil,
  pos: [0, 0],
  pos_fraction: [0, 0],
  ai: nil,
  color: Naghavi::Color::WHITE,
  tint: Naghavi::Color::WHITE,
  image_key: nil,
  image_frame: 0,
  animation: nil,
  alive: true,
  orientation: :north,
  pushable: false,
  teleport_pair: nil,
  just_teleported: false,
  deadly: true,
}}

Movement = Naghavi::DefStruct.new {{
  entity: nil,
  from: [0, 0],
}}

MovementSet = Naghavi::DefStruct.new {{
  movements: [],
  progress: 0.0,
}}

GameState = Naghavi::DefStruct.new {{
  level: nil,
  player: nil,
  goal: nil,
  entities: [],
  movement_sets: [],
}}

AiResults = Naghavi::DefStruct.new {{
  moves: [],
  spawns: [],
  kills: [],
}}

Cell = Naghavi::DefStruct.new {{
  type: :none,
  image_frame: 0,
  orientation: :north,
  sprite: nil,
}}

Level = Naghavi::DefStruct.new {{
  rows: [],
  entities: [],
}}.reopen do
  def self.from_text(file_string)
    rows = file_string.lines.map do |line|
      line.chomp("\n").each_char.map do |char|
        Cell.new(type: CELL_TYPES_BY_CHAR.fetch(char))
      end
    end
    self.new(rows: rows)
  end

  def each_cell
    rows.each_with_index do |row, row_idx|
      row.each_with_index do |cell, col_idx|
        yield([col_idx, row_idx], cell)
      end
    end
  end

  def cell_at(x, y)
    self.rows[y][x]
  end

  def row_count
    self.rows.size
  end

  def column_count
    self.rows.first.size
  end

  def can_move_to?(x, y)
    cell = cell_at(x, y)
    cell.type == :floor
  end
end

def orientation_for_movement(x, y)
  case
  when x > 0 then :east
  when x < 0 then :west
  when y > 0 then :south
  else :north
  end
end

class ChaserAi
  def think(chaser, game)
    e = chaser.pos
    p = game.player.pos
    dist = Naghavi.distance(e.x, e.y, p.x, p.y)

    moves = []
    if dist < 3.5
      if e.x < p.x then moves << [1, 0] end
      if e.x > p.x then moves << [-1, 0] end
      if e.y > p.y then moves << [0, -1] end
      if e.y < p.y then moves << [0, 1] end
    end

    AiResults.new(moves: moves)
  end
end

class ShooterAi
  def initialize
    @projectile = nil
  end

  def think(shooter, game)
    @projectile = nil if @projectile && !@projectile.alive
    return AiResults.new if @projectile

    p = game.player.pos
    s = shooter.pos
    projectile_vel =
      if p.x == s.x
        [0, (p.y < s.y ? -1 : 1)]
      elsif p.y == s.y
        [(p.x < s.x ? -1 : 1), 0]
      else
        nil
      end

    if projectile_vel
      shooter.orientation = orientation_for_movement(projectile_vel.x, projectile_vel.y)
      @projectile = Entity.new({
        pos: shooter.pos.dup,
        ai: ProjectileAi.new(projectile_vel),
        animation: Animation.new(image_key: :bullet),
      })
      AiResults.new(spawns: [@projectile])
    else
      AiResults.new
    end
  end
end

class ProjectileAi
  def initialize(velocity)
    @velocity = velocity
  end

  def think(projectile, game)
    new_pos = projectile.pos.vadd(@velocity)
    if game.level.can_move_to?(*new_pos)
      kills = game.entities.select { |e| e.pos == new_pos }
      kills << projectile if kills.size > 0
      AiResults.new({
        moves: [@velocity],
        kills: kills,
      })
    else
      AiResults.new(kills: [projectile])
    end
  end
end

class LevelScene < Naghavi::Scene
  def initialize(level_number)
    @level_number = level_number
  end

  def startup
=begin
    # TODO: implement this
    if !Gremlin::Song.current_song
      @@song = Gremlin::Song.new(w, 'assets/audio/music.mp3')
      @@song.play(true)
    end
=end

    #TODO: show final "winner" screen when no more levels available
    # just loops back to level 1 at the moment
    level_text = w.get_text("level#{@level_number}")

    @game = GameState.new(level: Level.from_text(level_text))

    @game.entities ||= []
    @game.level.each_cell do |pos, cell|
      case cell.type
      when :player
        @game.player = Entity.new(pos: pos.dup, animation: Animation.new(image_key: :player))
        cell.type = :floor
      when :enemy
        @game.entities << Entity.new(pos: pos.dup, ai: ChaserAi.new, animation: Animation.new(image_key: :chaser))
        cell.type = :floor
      when :shooter
        @game.entities << Entity.new(pos: pos.dup, ai: ShooterAi.new, animation: Animation.new(image_key: :shooter))
        cell.type = :floor
      when :goal
        @game.goal = Entity.new(pos: pos.dup, animation: Animation.new(image_key: :goal, secs_per_frame: 0.2))
        cell.type = :floor
      when :dirtball
        @game.entities << Entity.new(pos: pos.dup, animation: Animation.new(image_key: :dirtball), pushable: true)
        cell.type = :floor
      when :teleporter
        @game.entities << Entity.new(pos: pos.dup, animation: Animation.new(image_key: :teleporter), teleport_pair: 1, deadly: false)
        cell.type = :floor
      end
    end

    @game.level.each_cell do |cell_pos, cell|
      num_frames = IMAGES_BY_KEY[cell.type].size
      cell.image_frame = rand(0...num_frames)
      cell.orientation = [:north, :south, :east, :west].sample

      cell.sprite = w.add_sprite(cell.type + cell.image_frame.to_s)
      cell.sprite.position.set!(cell_pos.x * GRID_SIZE + GRID_SIZE/2, cell_pos.y * GRID_SIZE + GRID_SIZE/2)
      cell.sprite.pivot.set!(cell.sprite.width / 2, cell.sprite.height / 2)
      cell.sprite.scale.set!(GRID_SIZE/cell.sprite.width, GRID_SIZE/cell.sprite.height)
      cell.sprite.rotation = ORIENTATION_ROTATIONS.fetch(cell.orientation)
    end

    (@game.entities + [@game.player, @game.goal]).each do |e|
      e.sprite = w.add_sprite(e.animation.image_key + e.animation.current_frame.to_s)
      e.sprite.position.set!(e.pos.x * GRID_SIZE + GRID_SIZE/2, e.pos.y * GRID_SIZE + GRID_SIZE/2)
      e.sprite.pivot.set!(e.sprite.width/2, e.sprite.height/2)
      e.sprite.scale.set!(GRID_SIZE/e.sprite.width, GRID_SIZE/e.sprite.height)
    end

    @level_number_text = w.add_text("Level #@level_number", fill: 'white')
    @level_number_text.position.set!(15, 15)
    
    play_sound('start.wav')
  end

  def button_down(button)
    if @game.movement_sets.size == 0
      case button
      when KEY_UP then move_player(0, -1)
      when KEY_DOWN then move_player(0, 1)
      when KEY_LEFT then move_player(-1, 0)
      when KEY_RIGHT then move_player(1, 0)
      when KEY_SPACEBAR then move_player(0, 0)
      when KEY_N then return LevelScene.new(next_level)
      when KEY_P then return LevelScene.new(next_level(-1))
      when KEY_Z then return LevelScene.new(@level_number)
      end
    end
  end

  def next_level(diff = 1)
    ((@level_number + diff - 1) % NUM_LEVELS) + 1
  end

  def move_player(dx, dy)
    move_set = MovementSet.new

    did_move = try_move(@game.player, dx, dy, move_set)
    @game.player.just_teleported = false if did_move

    @game.entities.each do |enemy|
      if enemy.ai
        ai_results = enemy.ai.think(enemy, @game)
        apply_ai(enemy, ai_results, move_set)
      end
    end

    @game.movement_sets << move_set if move_set.movements.size > 0
  end

  def apply_ai(entity, ai_results, move_set)
    ai_results.moves.each do |move|
      break if try_move(entity, move.x, move.y, move_set)
    end
    ai_results.spawns.each do |entity|
      entity.sprite = w.add_sprite(entity.animation.image_key + entity.animation.current_frame.to_s)
      entity.sprite.position.set!(entity.pos.x*GRID_SIZE + GRID_SIZE/2, entity.pos.y*GRID_SIZE + GRID_SIZE/2)
      entity.sprite.pivot.set!(entity.sprite.width/2, entity.sprite.height/2)
      entity.sprite.scale.set!(GRID_SIZE / entity.sprite.width, GRID_SIZE / entity.sprite.height )
      @game.entities << entity
    end
    ai_results.kills.each do |entity|
      entity.alive = false
    end
  end

  def try_move(entity, dx, dy, move_set)
    x = entity.pos.x + dx
    y = entity.pos.y + dy
    return if y < 0 || y >= @game.level.row_count
    return if x < 0 || x >= @game.level.column_count

    if @game.level.can_move_to?(x, y)
      existing = @game.entities.find { |e| e.pushable && e.pos == [x, y] }
      if !existing || try_move(existing, dx, dy, move_set)
        entity.pos.vset!([x, y])
        entity.orientation = orientation_for_movement(dx, dy)
        move_set.movements << Movement.new(entity: entity, from: [-dx, -dy])
        true
      else
        false
      end
    else
      false
    end
  end

  def update
    update_animation(@game.player)
    update_animation(@game.goal)
    @game.entities.each do |entity|
      update_animation(entity) if entity.animation
    end

    did_move = update_next_movement
    @game.player.animation.secs_per_frame = did_move ? 0.02 : 0.3

    # TODO: refactor
    # sets every attribute on the sprite
    (@game.entities + [@game.player]).each do |e|
      e.sprite.position.set!((e.pos.x + e.pos_fraction.x) * GRID_SIZE + GRID_SIZE/2,
                             (e.pos.y + e.pos_fraction.y) * GRID_SIZE + GRID_SIZE/2)
      e.sprite.rotation = ORIENTATION_ROTATIONS.fetch(e.orientation)
    end

    return if did_move #no updating while moving

    if @game.player.pos == @game.goal.pos
      play_sound('win.wav')
      return EndLevelScene.new('You win!', Naghavi::Color::YELLOW, 'continue to next level', next_level)
    elsif @game.entities.any? { |e| e.deadly && e.pos == @game.player.pos }
      play_sound('lose.wav')
      return EndLevelScene.new('You lose', Naghavi::Color::RED, 'try again', @level_number)
    end

    teleporter = @game.entities.find { |e| e.teleport_pair && e.pos == @game.player.pos }
    if teleporter && !@game.player.just_teleported
      @game.player.just_teleported = true
      other_teleporter = @game.entities.find { |e| e.teleport_pair == teleporter.teleport_pair && e != teleporter }
      @game.player.pos = other_teleporter.pos.dup
    end

    @game.entities.select! do |e|
      if e.alive
        true
      else
        e.sprite.destroy!
        false
      end
    end

  end

  def update_animation(entity)
    anim = entity.animation
    anim.secs_elapsed_this_frame += w.delta_time
    old_frame = anim.current_frame
    while anim.secs_elapsed_this_frame >= anim.secs_per_frame
      anim.secs_elapsed_this_frame -= anim.secs_per_frame
      anim.current_frame += 1
      anim.current_frame = 0 if anim.current_frame >= IMAGES_BY_KEY[anim.image_key].size
    end

    if anim.current_frame != old_frame
      entity.sprite.image_key = anim.image_key + anim.current_frame.to_s
    end
  end

  def update_next_movement
    move_set = @game.movement_sets.first
    if move_set
      play_sound('move.wav') if move_set.progress <= 0.0

      move_set.progress += (w.delta_time / MOVE_INTERVAL)
      move_set.movements.each do |m|
        m.entity.pos_fraction.vset!(Naghavi.vlerp(m.from, [0,0], move_set.progress))
      end

      @game.movement_sets.shift if move_set.progress >= 1.0
    end

    !!move_set
  end

  def draw_entity(entity)
    pos = entity.pos.vadd(entity.pos_fraction)
    if entity.animation
      draw_entity_img(pos, entity.animation.image_key, entity.orientation, entity.animation.current_frame, entity.tint)
    elsif entity.image_key
      draw_entity_img(pos, entity.image_key, entity.orientation, entity.image_frame, entity.tint)
    else
      draw_entity_solid(pos, entity.color)
    end
  end

  def draw_entity_solid(cell_pos, color)
    pos = cell_pos.vmul(GRID_SIZE)
    w.draw_quad(pos.x, pos.y, color,
                pos.x + GRID_SIZE, pos.y, color,
                pos.x + GRID_SIZE, pos.y + GRID_SIZE, color,
                pos.x, pos.y + GRID_SIZE, color,
                0)
  end

  def play_sound(filename, *args)
    #TODO: implement this
    #Gremlin::Sample.new(w, "assets/audio/#{filename}").play(*args)
  end
end

class EndLevelScene < Naghavi::Scene
  def initialize(text, color = Naghavi::Color::WHITE, action_text = 'continue', next_level = 1)
    @text = text
    @color = color
    @action_text = action_text
    @next_level = next_level
  end

  def button_down(button)
    if button == KEY_SPACEBAR
      return LevelScene.new(@next_level)
    end
  end

  def startup
    screen = w.game_size

    top = w.add_text(@text, fill: @color)
    top.position.set!(screen.x/2 - top.width/2, screen.y/2)

    bot = w.add_text("Press space to #{@action_text}", fill: @color)
    bot.position.set!(screen.x/2 - bot.width/2, screen.y/2 + 80)
  end
end

class IntroScene < Naghavi::Scene
  def startup
    @background = w.add_sprite(:intro_background)
  end

  def button_down(button)
    LevelScene.new(1)
  end
end

# TODO: refactor IMAGES_BY_KEY so it fits better
assets = {
  images: Hash[
    IMAGES_BY_KEY.flat_map do |key, images|
      images.each_with_index.map do |img_name, idx|
        [ key + idx.to_s, 'assets/images/' + img_name ]
      end
    end
  ].merge({
    intro_background: 'assets/images/titlescreen.png',
  }),

  text: Hash[
    (1..NUM_LEVELS).map do |idx|
      ["level#{idx}", "assets/levels/#{idx}.txt"]
    end
  ]
}
nag_window = Naghavi::Window.new(LevelScene.new(5), assets)
game = Gremlin::Game.new(size: [13*GRID_SIZE, 10*GRID_SIZE], state: nag_window)
`window.game = game`
