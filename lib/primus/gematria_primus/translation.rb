class Primus::GematriaPrimus::Translation
  attr_reader :index, :rune, :letter, :value

  def initialize(index:, rune:, letter:, value:)
    @index = index
    @rune = rune
    @letter = letter
    @value = value
  end
end
