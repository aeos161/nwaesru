class Primus::Lexer::Factory
  def initialize(strategy: :runic)
    @strategy = (strategy || :runic).to_sym
  end

  def build
    case
    when strategy == :english
      Primus::Lexer::English.new
    when strategy == :runic
    else
      fail "no lexer for #{strategy}"
    end

  end

  protected

  attr_reader :strategy
end
