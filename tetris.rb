require "starruby"
include StarRuby

BLOCK_SIZE = 32
FIELD_ROW = 20
FIELD_COL = 10
FIELD_W = BLOCK_SIZE * FIELD_COL
FIELD_H = BLOCK_SIZE * FIELD_ROW

white = Color.new(255, 255, 255)

y = 0
x = 8
Game.run(FIELD_W, FIELD_H, :title => "tetris") do |game|
  break if Input.keys(:keyboard).include?(:escape)
  x += 8 if Input.keys(:keyboard).include?(:right)
  x -= 8 if Input.keys(:keyboard).include?(:left)

  y += 1
  y = 0 if y > 240

  game.screen.clear
  game.screen.render_rect(x, y, 16, 16, white)
end