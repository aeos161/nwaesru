class Primus::Token::WordDelimiter < Primus::Token
  IDENTIFIER = "-".freeze
  LITERAL = " ".freeze

  def initialize(location: nil)
    super(lexeme: IDENTIFIER, literal: LITERAL, location: location)
  end

  def delimiter?
    true
  end
end
