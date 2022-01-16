class Primus::Token::SentenceDelimiter < Primus::Token
  IDENTIFIER = ".".freeze

  def initialize(location: nil)
    super(lexeme: IDENTIFIER, literal: IDENTIFIER, location: location)
  end

  def delimiter?
    true
  end
end
