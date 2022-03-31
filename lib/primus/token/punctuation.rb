class Primus::Token::Punctuation < Primus::Token
  IDENTIFIER = /[:;'"!,?]/

  def initialize(lexeme:)
    super(lexeme: lexeme, literal: lexeme, location: nil)
  end

  def delimiter?
    true
  end
end
