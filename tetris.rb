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
FONT = Font.new("/Library/Fonts/Arial Bold.ttf", 24)



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

  def draw_text(str, col, row)
    render_text(str, col * BLOCK_SIZE,  row * BLOCK_SIZE, FONT, Color.new(0, 0, 0))
  end

  def draw_number(num)
    font_width, font_height = FONT.get_size(num.to_s)
    margin_width, margin_height = 5, 0
    x = self.width  - font_width  - margin_width
    y = self.height - font_height - margin_height
    render_text(num.to_s, x,  y, FONT, Color.new(0, 0, 0))
  end

  def draw_message(str)
    font = Font.new("/Library/Fonts/Arial Bold.ttf", 36)
    font_width, font_height = font.get_size(str)
    x = (self.width  - font_width ) / 2
    y = (self.height - font_height) / 2
    render_text(str, x,  y, font, Color.new(255, 255, 255))
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
    @pause_overlay.fill(Color.new(0, 0, 0, 160))
    @pause_overlay.draw_message("Pause")

    @gameover_overlay = Texture.new(WINDOW_W, WINDOW_H)
    @gameover_overlay.fill(Color.new(0, 0, 0, 160))
    @gameover_overlay.draw_message("Game Over")
  end
  
  def update(sender)
    @field_view.fill(Color.new(0, 0, 0, 128))
    @score_view.fill(Color.new(0, 0, 0, 128))
    @lines_view.fill(Color.new(0, 0, 0, 128))
    @next_view.fill(Color.new(255, 255, 255, 128))

    @field_view.draw_field(sender.field)
    @field_view.draw_tetrimino(sender.tetrimino)
    @score_view.draw_number(sender.score_counter)
    @lines_view.draw_number(sender.lines_counter)
    @next_view.draw_tetrimino(sender.nextmino)

    @screen.fill(Color.new(255, 255, 255))
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
    @field     = Field.new(FIELD_ROW, FIELD_COL)
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

    dx =  1 if Input.keys(:keyboard, {:duration => 1, :delay => 3, :interval => 1}).include?(:right)
    dx = -1 if Input.keys(:keyboard, {:duration => 1, :delay => 3, :interval => 1}).include?(:left)
    dy =  1 if Input.keys(:keyboard, {:duration =>-1, :delay =>-1, :interval => 0}).include?(:down)
    dr =  1 if Input.keys(:keyboard, {:duration => 1, :delay => 3, :interval => 3}).include?(:x)
    dr =  3 if Input.keys(:keyboard, {:duration => 1, :delay => 3, :interval => 3}).include?(:z)
    if @field.state == :dead then
      @state = :gameover
      return
    end

    @tetrimino.rotate(dr)
    @tetrimino.side_step(dx)
    @tetrimino.fall(dy)

    if @tetrimino.state == :dead then
      @field.import(@tetrimino)
      n = @field.clear_lines
      @score_counter += n**2 * 100
      @lines_counter += n
      @field.freeze if @tetrimino.y <= 0

      @tetrimino = @nextmino
      @nextmino  = Tetrimino.new(@game, @field)
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

  def toggle_state
    if    @state == :play then
      @state = :pause
    elsif @state == :pause then
      @state = :play
    elsif @state == :gameover then
      @state = :reset
    end
  end

end



Game.run(WINDOW_W, WINDOW_H, :title => "tetris") do |game|
  @dealer ||= Dealer.new(game)
  break if Input.keys(:keyboard).include?(:escape)
  @dealer.toggle_state if Input.keys(:keyboard, {:duration => 1, :delay => -1, :interval => 0}).include?(:space)
  @dealer.update
end