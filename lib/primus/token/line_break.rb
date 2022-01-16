class Primus::Token::LineBreak < Primus::Token
  IDENTIFIER = "/".freeze
  LITERAL = "\n".freeze

  def initialize(location: nil)
    super(lexeme: IDENTIFIER, literal: LITERAL, location: location)
  end

  def delimiter?
    true
  end

  def line_break?
    true
  end
end

