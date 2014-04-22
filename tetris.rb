require "starruby"
include StarRuby

white = Color.new(255, 255, 255)

y = 0
x = 8
Game.run(320, 240, :title => "tetris") do |game|
  break if Input.keys(:keyboard).include?(:escape)
  x += 8 if Input.keys(:keyboard).include?(:right)
  x -= 8 if Input.keys(:keyboard).include?(:left)

  y += 1
  y = 0 if y > 240

  game.screen.clear
  game.screen.render_rect(x, y, 16, 16, white)
end