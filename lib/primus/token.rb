class Primus::Token
  attr_reader :lexeme, :literal
  attr_accessor :location

  def initialize(lexeme: "", literal: nil, location: nil)
    @lexeme = lexeme
    @literal = literal
    @location = location
  end

  def ==(token)
    lexeme == token.lexeme && literal == token.literal
  end

  def to_s(format = nil)
    return lexeme if format == :rune
    literal.to_s
  end

  def accept(visitor)
    visitor.visit_token(self)
  end
end
