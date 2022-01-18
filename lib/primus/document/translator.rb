class Primus::Document::Translator
  attr_reader :dictionary

  def initialize(dictionary: nil)
    @dictionary = dictionary || Primus::GematriaPrimus.build
  end

  def visit_word(word)
    tokens = word.map do |tk|
      token = dictionary.find_by(rune: tk.lexeme)
      token.location = tk.location
      token
    end
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end
end
