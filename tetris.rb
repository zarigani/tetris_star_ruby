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
  attr_reader :blocks, :x, :y
  
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
    @x, @y = 3, 0
  end
  
  def side_step(dx)
    @x += dx
  end
  
  def fall(dy)
    @y += dy
  end
  
end



Game.run(FIELD_W, FIELD_H, :title => "tetris") do |game|
  @tetrimino ||= Tetrimino.new
  dx = 0
  dy = 0.125
  
  break if Input.keys(:keyboard).include?(:escape)
  dx =  1 if Input.keys(:keyboard).include?(:right)
  dx = -1 if Input.keys(:keyboard).include?(:left)

  @tetrimino.side_step(dx)
  @tetrimino.fall(dy)
  @tetrimino = nil if @tetrimino.y >= FIELD_ROW

  game.screen.clear
  game.screen.draw_tetrimino(@tetrimino)
end