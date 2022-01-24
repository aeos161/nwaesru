class Primus::GematriaPrimus::Token
  attr_reader :index, :rune, :letter, :value, :frequency

  attr_accessor :location

  def initialize(index: nil, rune: nil, letter: nil, value: nil,
                 frequency: nil)
    @index = index
    @rune = rune
    @letter = letter
    @value = value
    @frequency = frequency
  end

  def ==(token)
    index == token.index &&
      rune == token.rune &&
      letter == token.letter &&
      value == token.value
  end

  def to_s(method = :rune)
    return rune if method == :rune
    letter
  end

  def present?
    true unless value.nil?
  end
end
