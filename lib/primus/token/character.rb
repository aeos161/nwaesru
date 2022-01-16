class Primus::Token::Character < Primus::Token
  def initialize(lexeme:, location: nil)
    super(lexeme: lexeme, literal: lexeme, location: location)
  end

  def delimiter?
    false
  end
end
