class Primus::GematriaPrimus::NoTranslation
  attr_reader :rune, :letter, :value

  def initialize(letter: " ")
    @rune = letter
    @letter = letter
    @value = nil
  end
end
