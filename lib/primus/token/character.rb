class Primus::Token::Character < Primus::Token
  def initialize(lexeme:, location: nil)
    super(lexeme: lexeme, literal: lexeme, location: location)
  end

  def ==(token)
    lexeme == token.lexeme && literal == token.literal
  end

  def delimiter?
    false
  end
end
