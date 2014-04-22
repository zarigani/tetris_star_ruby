require "starruby"
include StarRuby

BLOCK_SIZE = 32
FIELD_ROW = 20
FIELD_COL = 10
FIELD_W = BLOCK_SIZE * FIELD_COL
FIELD_H = BLOCK_SIZE * FIELD_ROW



class Texture
  def draw_block(x, y)
    render_rect(x * BLOCK_SIZE + 1, y * BLOCK_SIZE + 1, BLOCK_SIZE - 1, BLOCK_SIZE - 1, Color.new(255, 255, 255))
  end

  def draw_tetrimino(tetrimino)
    return if !tetrimino
    tetrimino.blocks.each_with_index do |row, r|
      row.each_with_index do |col, c|
        draw_block(tetrimino.x + c , tetrimino.y + r) if col == 1
      end
    end
  end

end

class Tetrimino
  attr_reader :state, :x, :y
  
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
  
  def initialize
    @id = rand(0..6)
    @blocks = @@minos[@id]
    @x, @y, @angle = 3, 0, 0
    @state = :live
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
    if can_move?(0, 1, 0) then
      @y += dy
    else
      @state = :dead
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
             y + r >= FIELD_ROW then
            return false
          end
        end
      end
    end
    true
  end
  
end



Game.run(FIELD_W, FIELD_H, :title => "tetris") do |game|
  @tetrimino ||= Tetrimino.new
  dx = 0
  dy = 0.125
  dr = 0
  
  break if Input.keys(:keyboard).include?(:escape)
  dx =  1 if Input.keys(:keyboard).include?(:right)
  dx = -1 if Input.keys(:keyboard).include?(:left)
  dr =  1 if Input.keys(:keyboard).include?(:x)
  dr =  3 if Input.keys(:keyboard).include?(:z)

  @tetrimino.rotate(dr)
  @tetrimino.side_step(dx)
  @tetrimino.fall(dy)
  @tetrimino = nil if @tetrimino.state == :dead

  game.screen.clear
  game.screen.draw_tetrimino(@tetrimino)
end