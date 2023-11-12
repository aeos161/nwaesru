class Primus::Token::LineBreak < Primus::Token
  LITERAL = "\n".freeze

  def initialize(lexeme: LITERAL, location: nil)
    super(lexeme: lexeme, literal: LITERAL, location: location)
  end

  def line_break?
    true
  end
end

