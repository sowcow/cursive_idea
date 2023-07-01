require 'pathname'
require_relative 'draw'

task :say do
  text = ARGV[1..] * ' '
  DrawContext.new.say text
  exit 0
end

task :see => :show
task :show do
  text = ARGV[1..] * ' '
  DrawContext.new.say text, true
  exit 0
end

dir = 'alphabet'
task :alphabet do
  Pathname(dir).mkpath
  DrawContext.new(dx: 200).SIGNATURES.each { |x| x.draw dir, true }
end

task :table => :alphabet do
  files = [*?a..?z].map { |x| File.join(dir, x) + '.png' } * ' '
  system "montage -tile 5x -geometry +100+100 #{files} table.png"
  system "mogrify -resize 1000x table.png"
end
