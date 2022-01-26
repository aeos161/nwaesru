class Primus::GematriaPrimus::Token
  include Comparable

  attr_reader :index, :rune, :letter, :value, :frequency

  attr_accessor :location

  @@alphabet = nil

  def initialize(index: nil, rune: nil, letter: nil, value: nil,
                 frequency: nil)
    @index = index
    @rune = rune
    @letter = letter
    @value = value
    @frequency = frequency
  end

  def <=>(token)
    to_i <=> token.to_i
  end

  def ==(token)
    index == token.index &&
      rune == token.rune &&
      letter == token.letter &&
      value == token.value
  end

  def +(token)
    to_i + token.to_i
  end

  def -(token)
    to_i - token.to_i
  end

  def to_i
    value.to_i
  end

  def to_s(method = :rune)
    return rune if method == :rune
    letter
  end

  def present?
    true unless value.nil?
  end

  def factors(token)
    letters = alphabet.reject { |tk| tk >= self }
    res = letters.size.downto(1).flat_map { |n| letters.combination(n).to_a }
    res.
      select { |combo| combo.map(&:to_i).sum == value }.
      select { |combo| combo.include? token }
  end

  private

  def alphabet
    @@alphabet ||= Primus::GematriaPrimus.build
  end
end
