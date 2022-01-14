class Primus::GematriaPrimus::Token
  attr_reader :index, :rune, :letter, :value

  def initialize(index:, rune:, letter:, value:)
    @index = index
    @rune = rune
    @letter = letter
    @value = value
  end

  def ==(token)
    index == token.index &&
      rune == token.rune &&
      letter == token.letter &&
      value == token.value
  end

  def present?
    true
  end
end
