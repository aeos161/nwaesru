class Primus::LiberPrimus::Parser
  attr_reader :lines, :result

  def initialize(lines:)
    @lines = lines
    @result = []
  end

  def parse
    translator = Primus::GematriaPrimus.build
    split_by_char = Proc.new { |string| string.split("") }
    tokenize = Proc.new { |char| translator.find_by(rune: char) }
    @result = lines.map(&split_by_char).map { |line| line.map(&tokenize) }
  end
end
