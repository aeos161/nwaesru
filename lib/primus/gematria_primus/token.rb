class Primus::GematriaPrimus::Token
  attr_reader :index, :rune, :letter, :value

  attr_accessor :location

  def initialize(index: nil, rune:, letter:, value: nil)
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
    true unless value.nil?
  end
end
