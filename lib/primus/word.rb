class Primus::Word
  include Enumerable

  attr_reader :tokens

  @@alphabet = nil

  def initialize(tokens: [])
    @tokens = tokens
  end

  def ==(word)
    tokens == word.tokens
  end

  def <<(token)
    @tokens << token
  end

  def +(word)
    letters = tokens.zip(word.tokens).map(&method(:modular_addition))
    new_tokens = letters.map { |index| alphabet.find_by(index: index) }
    Primus::Word.new(tokens: new_tokens)
  end

  def -(word)
    letters = tokens.zip(word.tokens).map(&method(:modular_subtraction))
    new_tokens = letters.map { |index| alphabet.find_by(index: index.abs) }
    Primus::Word.new(tokens: new_tokens)
  end

  def each(&block)
    tokens.each(&block)
  end

  def to_s(method = :rune)
    tokens.map { |tk| tk.to_s(method) }.join
  end

  def size
    tokens.size
  end

  def blank?
    true if tokens.empty?
  end

  def sum
    map(&:to_i).sum(0)
  end

  def accept(visitor)
    visitor.visit_word(self)
  end

  protected

  attr_reader :alphabet

  def alphabet
    @@alphabet ||= Primus::GematriaPrimus.build
  end

  def modular_addition(terms)
    return terms[0].index if terms[1].nil?
    (terms[0].index + terms[1].index) % alphabet.size
  end

  def modular_subtraction(terms)
    return terms[0].index if terms[1].nil?
    (terms[0].index - terms[1].index) % alphabet.size
  end
end
