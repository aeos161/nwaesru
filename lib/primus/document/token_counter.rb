class Primus::Document::TokenCounter
  attr_reader :result

  def initialize(alphabet: nil)
    @alphabet ||= Primus::GematriaPrimus.build
    @result = []
  end

  def to_s
    alphabet.map(&:letter).zip(@result)
  end

  def visit_word(word)
    word.each do |token|
      @result[token.index] ||= 0
      @result[token.index] += 1
    end
    word
  end

  def visit_token(token)
    token
  end

  private

  attr_reader :alphabet
end
