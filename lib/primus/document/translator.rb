class Primus::Document::Translator
  attr_reader :dictionary

  def initialize(dictionary: nil)
    @dictionary = dictionary || Primus::GematriaPrimus.build
  end

  def visit_word(word)
    tokens = word.map { |tk| dictionary.find_by(rune: tk.lexeme) }
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end
end
