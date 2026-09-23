class Primus::Token
  attr_reader :lexeme, :literal
  attr_accessor :location, :source_location

  def initialize(lexeme: "", literal: nil, location: nil, source_location: nil)
    @lexeme = lexeme
    @literal = literal
    @location = location
    @source_location = source_location
  end

  def ==(token)
    lexeme == token.lexeme && literal == token.literal
  end

  def to_s(format = nil)
    return lexeme if format == :rune
    literal.to_s
  end

  def delimiter?
    false
  end

  def line_break?
    false
  end

  def accept(visitor)
    visitor.visit_token(self)
  end

  def sum
    0
  end
end
