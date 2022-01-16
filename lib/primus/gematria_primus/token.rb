class Primus::GematriaPrimus::Token
  attr_reader :index, :rune, :letter, :value

  def initialize(index: nil, rune:, letter:, value: nil)
    @index = index
    @rune = rune
    @letter = letter
    @value = value
  end

  def present?
    true unless value.nil?
  end
end
