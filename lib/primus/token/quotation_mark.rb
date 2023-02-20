class Primus::Token::QuotationMark < Primus::Token
  def initialize(lexeme:, location: nil)
    super(lexeme: lexeme, literal: "\"", location: location)
  end

  def delimiter?
    false
  end
end
