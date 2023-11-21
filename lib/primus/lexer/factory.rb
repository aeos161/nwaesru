class Primus::Lexer::Factory
  def initialize(strategy: :runic)
    @strategy = (strategy || :runic).to_sym
  end

  def build(data: "", line: 0, position: 0)
    case strategy.to_sym
    when :latin
      Primus::Lexer::Latin.new(data: data, line: line, position: position)
    when :runic
      Primus::Lexer::Runic.new(data: data, line: line, position: position)
    else
      fail "No lexer for: #{strategy}"
    end
  end

  protected

  attr_reader :strategy
end
