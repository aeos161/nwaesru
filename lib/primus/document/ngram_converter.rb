class Primus::Document::NgramConverter
  attr_reader :result, :count

  def initialize(document:, length: 2)
    @document = document
    @length = length
    @result = nil
    @count = []
  end

  def convert
    text = document.tokens.to_enum.each_slice(length).reduce([]) do |m, tokens|
      count tokens
      append tokens, to: m
    end
    text.pop
    @result = Primus::Document.new(text: text)
  end

  protected

  attr_reader :document, :length

  def count(tokens)
    @count[tokens[0].index] ||= []
    @count[tokens[0].index][tokens[1].index] ||= 0
    @count[tokens[0].index][tokens[1].index] += 1
  end

  def append(tokens, to:)
    tokens = [tokens[0], Primus::Token::Punctuation.new(lexeme: "."), tokens[1]]
    to << Primus::Word.new(tokens: tokens)
    to << Primus::Token::WordDelimiter.new
    to
  end
end
