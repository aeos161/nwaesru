class Primus::Document::NgramConverter
  attr_reader :result

  def initialize(document:, length: 2)
    @document = document
    @length = length
    @result = nil
  end

  def convert
    text = document.tokens.to_enum.each_slice(length).reduce([]) do |m, tokens|
      tokens = [tokens[0], Primus::Token::Punctuation.new(lexeme: "."), tokens[1]]
      m << Primus::Word.new(tokens: tokens)
      m << Primus::Token::WordDelimiter.new
      m
    end
    text.pop
    @result = Primus::Document.new(text: text)
  end

  protected

  attr_reader :document, :length
end
