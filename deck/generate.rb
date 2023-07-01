require 'anki2'

deck = Anki2.new({
  name: 'Own Cursive Font', 
  output_path: 'OwnCursiveFont.apkg'
})

[*?a..?z].each { |x|
  deck.add_card %'<img src="#{x}.png">', x
}
deck.add_media File.expand_path '../alphabet'
deck.save
