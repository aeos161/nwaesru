class Primus::Token::Punctuation < Primus::Token
  IDENTIFIER = /[:;'"!,?]/

  def initialize(lexeme:, location: nil)
    super(lexeme: lexeme, literal: lexeme, location: location)
  end

  def delimiter?
    true
  end
end
