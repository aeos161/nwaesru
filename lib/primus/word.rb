class Primus::Word
  include Enumerable

  attr_reader :tokens

  def initialize(tokens: [])
    @tokens = tokens
  end

  def ==(word)
    tokens == word.tokens
  end

  def <<(token)
    @tokens << token
  end

  def each(&block)
    tokens.each(&block)
  end

  def to_s(method = :rune)
    tokens.map(&method).join
  end

  def size
    tokens.size
  end

  def blank?
    true if tokens.empty?
  end

  def accept(visitor)
    visitor.visit_word(self)
  end
end
