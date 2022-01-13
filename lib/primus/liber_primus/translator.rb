class Primus::LiberPrimus::Translator
  attr_reader :data, :strategy, :result

  def initialize(data:, strategy:)
    @data = data
    @strategy = strategy
  end

  def translate
    decode = Proc.new { |line| strategy.translate(line: line) }
    @result = Primus::Translation.new(lines: data.map(&decode))
  end

  def self.build(page:, strategy:)
    parser = Primus::LiberPrimus::Parser.new(lines: page.lines)
    parser.parse
    new(data: parser.result, strategy: strategy)
  end
end
