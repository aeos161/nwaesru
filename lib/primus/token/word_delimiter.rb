class Primus::Token::WordDelimiter < Primus::Token
  LITERAL = " ".freeze

  def initialize(lexeme:, location: nil)
    super(lexeme: lexeme, literal: LITERAL, location: location)
  end

  def delimiter?
    true
  end
end
