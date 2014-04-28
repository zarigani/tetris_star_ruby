require "starruby"
include StarRuby

BLOCK_SIZE = 32
FIELD_ROW = 20
FIELD_COL = 10
FIELD_W = BLOCK_SIZE * FIELD_COL
FIELD_H = BLOCK_SIZE * FIELD_ROW
WINDOW_ROW = 26
WINDOW_COL = 18
WINDOW_W = BLOCK_SIZE * WINDOW_COL
WINDOW_H = BLOCK_SIZE * WINDOW_ROW
RGBS = [[  0, 255, 255],
        [255, 255,   0],
        [  0, 255,   0],
        [255,   0,   0],
        [  0,   0, 255],
        [255, 127,   0],
        [255,   0, 255]]



class Texture
  def draw_block(x, y, rgb)
    render_rect(x * BLOCK_SIZE + 1, y * BLOCK_SIZE + 1, BLOCK_SIZE - 1, BLOCK_SIZE - 1, Color.new(*rgb))
  end

  def draw_tetrimino(tetrimino)
    return if !tetrimino
    tetrimino.blocks.each_with_index do |row, r|
      row.each_with_index do |col, c|
        draw_block(tetrimino.x + c , tetrimino.y + r, RGBS[tetrimino.id]) if col == 1
      end
    end
  end

  def draw_field(field)
    return if !field
    alpha = (field.state == :live ? 255 : 64)
    field.matrix.each_with_index do |row, r|
      row.each_with_index do |col, c|
        draw_block(c, r, RGBS[col] + [alpha]) if col != nil
      end
    end
  end

end

class Tetrimino
  attr_reader :id, :state, :x, :y
  
  @@minos = []
  @@minos << [[0,0,0,0],
              [1,1,1,1],
              [0,0,0,0],
              [0,0,0,0]]
  @@minos << [[1,1],
              [1,1]]
  @@minos << [[0,1,1],
              [1,1,0],
              [0,0,0]]
  @@minos << [[1,1,0],
              [0,1,1],
              [0,0,0]]
  @@minos << [[1,0,0],
              [1,1,1],
              [0,0,0]]
  @@minos << [[0,0,1],
              [1,1,1],
              [0,0,0]]
  @@minos << [[0,1,0],
              [1,1,1],
              [0,0,0]]
  
  def initialize(game, field)
    @game = game
    @field = field
    @id = rand(0..6)
    @blocks = @@minos[@id]
    @x, @y, @angle = 3, 0, 0
    @state = :live
    @last_chance = 0
  end
  
  def blocks(angle = @angle)
    case angle % 4
    when 0
      @blocks
    when 1
      @blocks.transpose.map(&:reverse)  #右90度回転
    when 2
      @blocks.reverse.map(&:reverse)    #180度回転
    when 3
      @blocks.transpose.reverse         #左90度回転（右270度回転）
    end
  end
  
  def rotate(dr)
    if can_move?(0, 0, dr) then
      @angle += dr
    end
  end
  
  def side_step(dx)
    if can_move?(dx, 0, 0) then
      @x += dx
    end
  end
  
  def fall(dy)
    @last_chance -= 1
    @y = @y.to_i if dy == 1
    if can_move?(0, 1, 0) then
      @y += dy
    else
      case
      when @last_chance < 0
        @last_chance = @game.fps / 2
      when @last_chance == 0
        @state = :dead
      end
    end
  end

  def can_move?(dx, dy, dr)
    x = @x + dx
    y = @y + dy
    angle = @angle + dr
    blocks(angle).each_with_index do |row, r|
      row.each_with_index do |col, c|
        if col == 1 then
          if x + c < 0 ||
             x + c >= FIELD_COL ||
             y + r >= FIELD_ROW ||
             @field.matrix[y + r][x + c] != nil then
            return false
          end
        end
      end
    end
    true
  end
  
end

class Field
  attr_reader :matrix, :state

  def initialize(row, col)
    @matrix = Array.new(row){Array.new(col)}
    @state = :live
  end

  def import(tetrimino)
    tetrimino.blocks.each_with_index do |row, r|
      row.each_with_index do |col, c|
        @matrix[tetrimino.y + r][tetrimino.x + c] = tetrimino.id if col == 1
      end
    end
  end

  def clear_lines
    @matrix.reject!{|row| !row.include?(nil)}
    deleted_line = FIELD_ROW - @matrix.size
    deleted_line.times{@matrix.unshift(Array.new(10){nil})}
  end

  def freeze
    @state = :dead
  end

end

class Frame
  def initialize(screen)
    @screen = screen
    @field_view = Texture.new(FIELD_W,               FIELD_H)
    @score_view = Texture.new(4 * BLOCK_SIZE, 1 * BLOCK_SIZE)
    @lines_view = Texture.new(4 * BLOCK_SIZE, 1 * BLOCK_SIZE)
    @next_view  = Texture.new(FIELD_W,        2 * BLOCK_SIZE)
  end
  
  def update(sender)
    @field_view.fill(Color.new(0, 0, 0, 128))
    @score_view.fill(Color.new(0, 0, 0, 128))
    @lines_view.fill(Color.new(0, 0, 0, 128))
    @next_view.fill(Color.new(0, 0, 0, 128))

    @field     = sender.instance_variable_get(:@field)
    @tetrimino = sender.instance_variable_get(:@tetrimino)

    @field_view.draw_field(@field)
    @field_view.draw_tetrimino(@tetrimino)

    @screen.fill(Color.new(255, 255, 255))
    @screen.render_texture(@field_view,  1 * BLOCK_SIZE,  5 * BLOCK_SIZE)
    @screen.render_texture(@score_view, 13 * BLOCK_SIZE,  6 * BLOCK_SIZE)
    @screen.render_texture(@lines_view, 13 * BLOCK_SIZE, 10 * BLOCK_SIZE)
    @screen.render_texture(@next_view ,  1 * BLOCK_SIZE,  2 * BLOCK_SIZE)
  end
end



Game.run(WINDOW_W, WINDOW_H, :title => "tetris") do |game|
  @field     ||= Field.new(FIELD_ROW, FIELD_COL)
  @tetrimino ||= Tetrimino.new(game, @field)
  @frame     ||= Frame.new(game.screen)
  dx = 0
  dy = 0.0625
  dr = 0
  
  break if Input.keys(:keyboard).include?(:escape)
  dx =  1 if Input.keys(:keyboard, {:duration => 1, :delay => 3, :interval => 1}).include?(:right)
  dx = -1 if Input.keys(:keyboard, {:duration => 1, :delay => 3, :interval => 1}).include?(:left)
  dy =  1 if Input.keys(:keyboard, {:duration =>-1, :delay =>-1, :interval => 0}).include?(:down)
  dr =  1 if Input.keys(:keyboard, {:duration => 1, :delay => 3, :interval => 3}).include?(:x)
  dr =  3 if Input.keys(:keyboard, {:duration => 1, :delay => 3, :interval => 3}).include?(:z)
  next if @field.state == :dead

  @tetrimino.rotate(dr)
  @tetrimino.side_step(dx)
  @tetrimino.fall(dy)

  if @tetrimino.state == :dead then
    @field.import(@tetrimino)
    @field.clear_lines
    @field.freeze if @tetrimino.y <= 0
    @tetrimino = nil
  end

  @frame.update(self)
end