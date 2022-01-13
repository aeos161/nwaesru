class Primus::Translator
  attr_reader :result, :strategy

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

  protected

  attr_reader :data
end
