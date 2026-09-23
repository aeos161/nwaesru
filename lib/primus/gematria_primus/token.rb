class Primus::GematriaPrimus::Token
  include Comparable

  attr_reader :index, :rune, :alt_letter, :value, :frequency

  attr_accessor :location, :letter, :source_location

  @@alphabet = nil

  def initialize(index: nil, rune: nil, letter: nil, value: nil,
                 frequency: nil, alt_letter: nil)
    @index = index
    @rune = rune
    @letter = letter
    @alt_letter = alt_letter
    @value = value
    @frequency = frequency
  end

  def <=>(token)
    return letter <=> token.letter if to_i == token.to_i
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

  def <<(token)
    return self if token.nil?
    shift = token.respond_to?(:index) ? token.index : token.to_i
    shifted_index = (index + shift) % alphabet.size
    new_token = alphabet.find_by(index: shifted_index)
    new_token.location = location
    new_token.source_location = source_location
    new_token
  end

  def >>(token)
    return self if token.nil?
    shift = token.respond_to?(:index) ? token.index : token.to_i
    shifted_index = (index - shift) % alphabet.size
    new_token = alphabet.find_by(index: shifted_index.abs)
    new_token.location = location
    new_token.source_location = source_location
    new_token
  end

  def ^(token)
    return self if token.nil?
    shift = token.respond_to?(:index) ? token.index : token.to_i
    xor_index = (index ^ shift) % alphabet.size
    new_token = alphabet.find_by(index: xor_index)
    new_token.location = location
    new_token.source_location = source_location
    new_token
  end

  def to_i
    value.to_i
  end

  def to_s(method = :rune, alt: false)
    return rune if method == :rune
    return alt_letter if alt
    letter
  end

  def present?
    true unless value.nil?
  end

  def alt?
    true unless alt_letter.nil?
  end

  def line_break?
    false
  end

  def accept(visitor)
    visitor.visit_token(self)
  end

  def factors(token)
    letters = alphabet.reject { |tk| tk >= self }
    res = letters.size.downto(1).flat_map { |n| letters.combination(n).to_a }
    res.
      select { |combo| combo.sum(&:to_i) == value }.
      select { |combo| combo.include? token }
  end

  private

  def alphabet
    @@alphabet ||= Primus::GematriaPrimus.build
  end
end
