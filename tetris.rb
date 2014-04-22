require "starruby"
include StarRuby

BLOCK_SIZE = 32
FIELD_ROW = 20
FIELD_COL = 10
FIELD_W = BLOCK_SIZE * FIELD_COL
FIELD_H = BLOCK_SIZE * FIELD_ROW

white = Color.new(255, 255, 255)

y = 0
x = 3
Game.run(FIELD_W, FIELD_H, :title => "tetris") do |game|
  break if Input.keys(:keyboard).include?(:escape)
  x += 1 if Input.keys(:keyboard).include?(:right)
  x -= 1 if Input.keys(:keyboard).include?(:left)

  y += 0.125
  y = 0 if y >= FIELD_ROW

  game.screen.clear
  game.screen.render_rect(x * BLOCK_SIZE, y * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE, white)
end