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
COLORS = [Color.new(  0, 255, 255), #0
          Color.new(255, 255,   0), #1
          Color.new(  0, 255,   0), #2
          Color.new(255,   0,   0), #3
          Color.new(  0,   0, 255), #4
          Color.new(255, 128,   0), #5
          Color.new(255,   0, 255), #6
          Color.new(255, 255, 255), #7
          Color.new(255, 255, 192)] #8
WHITE_COLOR     = Color.new(255, 255, 255)
WHITE_COLOR_128 = Color.new(255, 255, 255, 128)
BLACK_COLOR     = Color.new(0, 0, 0)
BLACK_COLOR_128 = Color.new(0, 0, 0, 128)
BLACK_COLOR_160 = Color.new(0, 0, 0, 160)
FONT_24 = Font.new("/Library/Fonts/Arial Bold.ttf", 24)
FONT_36 = Font.new("/Library/Fonts/Arial Bold.ttf", 36)



class Texture
  def draw_block(x, y, color)
    render_rect(x * BLOCK_SIZE + 1, y * BLOCK_SIZE + 1, BLOCK_SIZE - 1, BLOCK_SIZE - 1, color)
  end

  def draw_tetrimino(tetrimino, offset_x = 0, offset_y = 0)
    return if !tetrimino
    tetrimino.blocks.each_with_index do |row, r|
      row.each_with_index do |col, c|
        draw_block(tetrimino.x + c + offset_x , tetrimino.y + r + offset_y, COLORS[tetrimino.id]) if col == 1
      end
    end
  end

  def draw_field(field)
    return if !field
    field.matrix.each_with_index do |row, r|
      row.each_with_index do |col, c|
        draw_block(c, r, COLORS[col]) if col != nil
      end
    end
  end

  def draw_text(str, col, row)
    render_text(str, col * BLOCK_SIZE,  row * BLOCK_SIZE, FONT_24, BLACK_COLOR)
  end

  def draw_number(num)
    font_width, font_height = FONT_24.get_size(num.to_s)
    margin_width, margin_height = 5, 0
    x = self.width  - font_width  - margin_width
    y = self.height - font_height - margin_height
    render_text(num.to_s, x,  y, FONT_24, BLACK_COLOR)
  end

  def draw_message(str)
    font_width, font_height = FONT_36.get_size(str)
    x = (self.width  - font_width ) / 2
    y = (self.height - font_height) / 2
    render_text(str, x,  y, FONT_36, WHITE_COLOR)
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
    @blocks = [@@minos[@id],                          #回転なし
               @@minos[@id].transpose.map(&:reverse), #右90度回転
               @@minos[@id].reverse.map(&:reverse),   #180度回転
               @@minos[@id].transpose.reverse]        #左90度回転（右270度回転）
    @x, @y, @angle = (4 - @blocks.size) / 2 + 3, -1.9, 0
    @state = :falling
    @last_chance = 0
  end
  
  def blocks(angle = @angle)
    @blocks[angle % 4]
  end
  
  def rotate(dr)
    return if dr == 0
    if can_move?(0, 0, dr) then
      @angle += dr
      @last_chance = @game.fps * 0.5
    end
  end
  
  def side_step(dx)
    return if dx == 0
    if can_move?(dx, 0, 0) then
      @x += dx
      @last_chance = @game.fps * 0.5
    end
  end
  
  def fall(dy)
    @y = @y.to_i if dy == 1
    if can_move?(0, 1, 0) then
      @y += dy
      @last_chance = @game.fps * 0.5
    else
      @last_chance -= 1
      @state = :landed if @last_chance < 0
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

  def initialize(game, row, col)
    @game = game
    @matrix = Array.new(row){Array.new(col)}
    @state = :live
    @flash_counter = 0
  end

  def import(tetrimino)
    tetrimino.blocks.each_with_index do |row, r|
      row.each_with_index do |col, c|
        @matrix[tetrimino.y + r][tetrimino.x + c] = tetrimino.id if col == 1
      end
    end
  end

  def flash_lines
    @flash_counter -= 1
    case
    when @flash_counter < 0
      @flash_counter = @game.fps / 2
      @state = :flash
    when @flash_counter == 0
      @state = :clear
    end

    @matrix.each do |row|
      row.map! {|i| i = @flash_counter % 2 + 7} if row.all?
    end
  end

  def clear_lines
    @matrix.reject!{|row| row.all?}
    deleted_line = FIELD_ROW - @matrix.size
    deleted_line.times{@matrix.unshift(Array.new(10){nil})}
    deleted_line
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

    @pause_overlay    = Texture.new(WINDOW_W, WINDOW_H)
    @pause_overlay.fill(BLACK_COLOR_160)
    @pause_overlay.draw_message("Pause")

    @gameover_overlay = Texture.new(WINDOW_W, WINDOW_H)
    @gameover_overlay.fill(BLACK_COLOR_160)
    @gameover_overlay.draw_message("Game Over")
  end
  
  def update(sender)
    @field_view.fill(BLACK_COLOR_128)
    @score_view.fill(BLACK_COLOR_128)
    @lines_view.fill(BLACK_COLOR_128)
    @next_view.fill(WHITE_COLOR_128)

    @field_view.draw_tetrimino(sender.tetrimino)
    @field_view.draw_field(sender.field)
    @score_view.draw_number(sender.score_counter)
    @lines_view.draw_number(sender.lines_counter)
    @next_view.draw_tetrimino(sender.nextmino, 0, 1.9)

    @screen.fill(WHITE_COLOR)
    @screen.render_texture(@field_view,  1 * BLOCK_SIZE,  5 * BLOCK_SIZE)
    @screen.draw_text("SCORE", 13,  5)
    @screen.render_texture(@score_view, 13 * BLOCK_SIZE,  6 * BLOCK_SIZE)
    @screen.draw_text("LINES", 13,  9)
    @screen.render_texture(@lines_view, 13 * BLOCK_SIZE, 10 * BLOCK_SIZE)
    @screen.draw_text("NEXT", 4,  1)
    @screen.render_texture(@next_view ,  1 * BLOCK_SIZE,  2 * BLOCK_SIZE)
  end

  def overlay(mode)
    case mode
    when :pause    then @screen.render_texture(@pause_overlay    , 0, 0)
    when :gameover then @screen.render_texture(@gameover_overlay , 0, 0)
    end
  end

end

class Dealer
  attr_reader :state, :field, :nextmino, :tetrimino, :score_counter, :lines_counter

  def initialize(game = @game)
    @game    ||= game
    @state     = :play
    @field     = Field.new(game, FIELD_ROW, FIELD_COL)
    @nextmino  = Tetrimino.new(game, @field)
    @tetrimino = Tetrimino.new(game, @field)
    @frame     = Frame.new(game.screen)

    @score_counter = 0
    @lines_counter = 0
  end

  def update
    send(@state)
  end

  def play
    dx = 0
    dy = 0.0625
    dr = 0
    @game.fps = 30 + @lines_counter
    delay_fps = @game.fps / 10

    dx =  1 if Input.keys(:keyboard, {:duration => 1, :delay => delay_fps, :interval => delay_fps / 3}).include?(:right)
    dx = -1 if Input.keys(:keyboard, {:duration => 1, :delay => delay_fps, :interval => delay_fps / 3}).include?(:left)
    dy =  1 if Input.keys(:keyboard, {:duration =>-1, :delay =>        -1, :interval =>             0}).include?(:down)
    dr =  1 if Input.keys(:keyboard, {:duration => 1, :delay => delay_fps, :interval => delay_fps    }).include?(:x)
    dr =  3 if Input.keys(:keyboard, {:duration => 1, :delay => delay_fps, :interval => delay_fps    }).include?(:z)
    if @field.state == :dead then
      @state = :gameover
      return
    end

    if @tetrimino.state == :falling then
      @tetrimino.rotate(dr)
      @tetrimino.side_step(dx)
      @tetrimino.fall(dy)
    end

    if @tetrimino.state == :landed then
      @field.import(@tetrimino)
      @field.flash_lines
      if @field.state == :clear then
        n = @field.clear_lines
        @score_counter += n**2 * 100
        @lines_counter += n
        @field.freeze if @tetrimino.y < 0

        @tetrimino = @nextmino
        @nextmino  = Tetrimino.new(@game, @field)
      end
    end

    @frame.update(self)
  end

  def pause
    @frame.update(self)
    @frame.overlay(:pause)
  end

  def gameover
    @frame.update(self)
    @frame.overlay(:gameover)
  end

  def reset
    initialize
  end

  def switch_state
    case @state
    when :play     then @state = :pause
    when :pause    then @state = :play
    when :gameover then @state = :reset
    end
  end

end



Game.run(WINDOW_W, WINDOW_H, :title => "tetris") do |game|
  @dealer ||= Dealer.new(game)
  break if Input.keys(:keyboard).include?(:escape)
  @dealer.switch_state if Input.keys(:keyboard, {:duration => 1, :delay => -1, :interval => 0}).include?(:space)
  @dealer.update
end