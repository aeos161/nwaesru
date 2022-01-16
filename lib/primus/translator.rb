class Primus::Translator
  attr_reader :data, :result, :strategy

  def initialize(data:, strategy:)
    @data = data
    @strategy = strategy
  end

  def translate
    lexer = Primus::Lexer.new(data: data)
    lexer.tokenize
    parser = Primus::Parser.new(tokens: lexer.tokens)
    parser.parse
    document = parser.result
    @result = Primus::Translation.new(words: document.map(&self.method(:decode)))
  end

  def self.build(page:, strategy:)
    new(data: page.data, strategy: strategy)
  end

  protected

  def decode(word)
    return word unless word.is_a? Primus::Word
    strategy.translate(word: word)
  end
end
