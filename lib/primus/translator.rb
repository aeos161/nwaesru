class Primus::Translator
  attr_reader :result, :strategy

  def initialize(document:, strategy:)
    @document = document
    @strategy = strategy
  end

  def translate
    decode = Proc.new { |word| strategy.translate(word: word) }
    @result = Primus::Translation.new(words: document.map(&decode))
  end

  def self.build(page:, strategy:)
    parser = Primus::LiberPrimus::Parser.new(lines: page.lines)
    parser.parse
    new(document: parser.result, strategy: strategy)
  end

  protected

  attr_reader :document
end
