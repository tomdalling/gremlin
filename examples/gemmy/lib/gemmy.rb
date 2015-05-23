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

ANIMATIONS_FRAMES = {
  player: 3,
  chaser: 3,
  floor: 4,
  wall: 4,
  gems: 2,
  goal: 3,
  dirtball: 1,
  shooter: 5,
  bullet: 1,
  teleporter: 4,
}

Animation = Naghavi::DefStruct.new {{
  image_key: nil,
  current_frame: 0,
  secs_per_frame: 0.3,
  secs_elapsed_this_frame: 0,
}}

Entity = Naghavi::DefStruct.new {{
  sprite: nil,
  sort_order: 0,
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
      moves << [ 1,  0] if e.x < p.x
      moves << [-1,  0] if e.x > p.x
      moves << [ 0, -1] if e.y > p.y
      moves << [ 0,  1] if e.y < p.y
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
    return nil if @projectile

    p = game.player.pos
    s = shooter.pos
    projectile_vel = begin
      case
      when p.x == s.x then [0, (p.y < s.y ? -1 : 1)]
      when p.y == s.y then [(p.x < s.x ? -1 : 1), 0]
      else nil
      end
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
  ENTITY_SORT_ORDER = [:dirtball, :enemy, :player]

  def initialize(level_number)
    @level_number = level_number
  end

  def so(type)
    ENTITY_SORT_ORDER.index(type) || ENTITY_SORT_ORDER.size
  end

  def startup
    @@song = w.play_sound(:music, true) unless @@song

    #TODO: show final "winner" screen when no more levels available
    # just loops back to level 1 at the moment
    level_text = w.get_text("level#{@level_number}")

    @game = GameState.new(level: Level.from_text(level_text))

    @game.entities ||= []
    @game.level.each_cell do |pos, cell|
      case cell.type
      when :player
        @game.player = Entity.new(pos: pos.dup, animation: Animation.new(image_key: :player), sort_order: so(:player))
        cell.type = :floor
      when :enemy
        @game.entities << Entity.new(pos: pos.dup, ai: ChaserAi.new, animation: Animation.new(image_key: :chaser), sort_order: so(:enemy))
        cell.type = :floor
      when :shooter
        @game.entities << Entity.new(pos: pos.dup, ai: ShooterAi.new, animation: Animation.new(image_key: :shooter), sort_order: so(:enemy))
        cell.type = :floor
      when :goal
        @game.goal = Entity.new(pos: pos.dup, animation: Animation.new(image_key: :goal, secs_per_frame: 0.2), sort_order: so(:goal))
        cell.type = :floor
      when :dirtball
        @game.entities << Entity.new(pos: pos.dup, animation: Animation.new(image_key: :dirtball), pushable: true, sort_order: so(:dirtball))
        cell.type = :floor
      when :teleporter
        @game.entities << Entity.new(pos: pos.dup, animation: Animation.new(image_key: :teleporter), teleport_pair: 1, deadly: false, sort_order: so(:teleporter))
        cell.type = :floor
      end
    end

    @game.level.each_cell do |cell_pos, cell|
      num_frames = ANIMATIONS_FRAMES[cell.type]
      cell.image_frame = rand(0...num_frames)
      cell.orientation = [:north, :south, :east, :west].sample

      cell.sprite = w.add_sprite(cell.type + cell.image_frame.to_s)
      cell.sprite.position.set!(cell_pos.x * GRID_SIZE + GRID_SIZE/2, cell_pos.y * GRID_SIZE + GRID_SIZE/2)
      cell.sprite.pivot.set!(cell.sprite.width / 2, cell.sprite.height / 2)
      cell.sprite.scale.set!(GRID_SIZE/cell.sprite.width, GRID_SIZE/cell.sprite.height)
      cell.sprite.rotation = ORIENTATION_ROTATIONS.fetch(cell.orientation)
      `#{cell.sprite}.smoothed = false`
    end

    all_entities = @game.entities + [@game.player, @game.goal]

    all_entities.each do |e|
      e.sprite = w.add_sprite(e.animation.image_key + e.animation.current_frame.to_s)
      e.sprite.position.set!(e.pos.x * GRID_SIZE + GRID_SIZE/2, e.pos.y * GRID_SIZE + GRID_SIZE/2)
      e.sprite.pivot.set!(e.sprite.width/2, e.sprite.height/2)
      e.sprite.scale.set!(GRID_SIZE/e.sprite.width, GRID_SIZE/e.sprite.height)
      `#{e.sprite}.smoothed = false`
    end

    all_entities
      .sort_by(&:sort_order)
      .reverse
      .each{ |e| e.sprite.bring_to_top }

    @level_number_text = w.add_text("Level #{@level_number + 1}", fill: 'white')
    @level_number_text.position.set!(15, 15)

    w.play_sound(:start)
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
    (@level_number + diff) % NUM_LEVELS
  end

  def move_player(dx, dy)
    move_set = MovementSet.new

    did_move = try_move(@game.player, dx, dy, move_set)
    @game.player.just_teleported = false if did_move

    # explicit idx looping necessary because AI can spawn new entities during iteration
    idx = 0
    while idx < @game.entities.size
      enemy = @game.entities[idx]
      if enemy.ai
        ai_results = enemy.ai.think(enemy, @game)
        apply_ai(enemy, ai_results, move_set) if ai_results
      end

      idx += 1
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
      `#{entity.sprite}.smoothed = false`
      @game.entities << entity
    end
    ai_results.kills.each { |entity| entity.alive = false }
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
      w.play_sound(:win)
      return EndLevelScene.new('You win!', Naghavi::Color::YELLOW, 'continue to next level', next_level)
    elsif @game.entities.any? { |e| e.deadly && e.pos == @game.player.pos }
      w.play_sound(:lose)
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
      anim.current_frame = 0 if anim.current_frame >= ANIMATIONS_FRAMES[anim.image_key]
    end

    if anim.current_frame != old_frame
      entity.sprite.image_key = anim.image_key + anim.current_frame.to_s
    end
  end

  def update_next_movement
    move_set = @game.movement_sets.first
    if move_set
      w.play_sound(:move) if move_set.progress <= 0.0

      move_set.progress += (w.delta_time / MOVE_INTERVAL)
      move_set.movements.each do |m|
        m.entity.pos_fraction.vset!(Naghavi.vlerp(m.from, [0,0], move_set.progress))
      end

      @game.movement_sets.shift if move_set.progress >= 1.0
    end

    !!move_set
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
    case button
    when KEY_SPACEBAR then LevelScene.new(@next_level)
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
    `#{w}.stage.smoothed = false;`
  end

  def button_down(button)
    LevelScene.new(0)
  end
end

ASSETS = {
  image: [
    :intro_background,
    [:dirtball, 1],
    [:bullet, 1],
    [:player, 3],
    [:chaser, 3],
    [:wall, 4],
    [:goal, 3],
    [:floor, 4],
    [:shooter, 5],
    [:teleporter, 4],
  ],

  text: [
    [:level, NUM_LEVELS],
  ],

  audio: [
    :lose,
    :move,
    :start,
    :win,
    [:music, 'mp3'],
  ],
}

starting_scene = IntroScene.new
#starting_scene = LevelScene.new(5)
nag_window = Naghavi::Window.new(starting_scene, ASSETS)
game = Gremlin::Game.new(size: [13*GRID_SIZE, 10*GRID_SIZE], state: nag_window)
`window.game = game`
