class Primus::LiberPrimus::Translator
  attr_reader :page, :result, :strategy

  def initialize(page:, strategy:)
    @page = page
    @strategy = strategy
  end

  def translate
    @result = page.lines.map { |line| strategy.translate(line: line) }
  end
end
