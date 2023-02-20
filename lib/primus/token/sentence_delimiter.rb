class Primus::Token::SentenceDelimiter < Primus::Token
  IDENTIFIER = ".".freeze
  LITERAL = ". ".freeze

  def initialize(lexeme:, location: nil)
    super(lexeme: lexeme, literal: LITERAL, location: location)
  end

  def delimiter?
    true
  end
end
