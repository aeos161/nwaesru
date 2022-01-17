class Primus::Token
  attr_reader :lexeme, :literal, :location

  def initialize(lexeme: "", literal: nil, location: nil)
    @lexeme = lexeme
    @literal = literal
    @location = location
  end

  def ==(token)
    lexeme == token.lexeme &&
      literal == token.literal &&
      location == token.location
  end

  def to_s(*)
    literal.to_s
  end

  def accept(visitor)
    visitor.visit_token(self)
  end
end
