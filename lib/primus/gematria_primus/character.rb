class Primus::GematriaPrimus::Character < Primus::Token
  def initialize(lexeme:)
    super(lexeme: lexeme, literal: lexeme)
  end
end
