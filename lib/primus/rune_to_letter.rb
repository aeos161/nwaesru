class Primus::RuneToLetter
  attr_reader :translator

  def initialize(translator:)
    @translator = translator
  end

  def translate(word:)
    tokens = word.map { |tk| translator.find_by(rune: tk.lexeme) }
    Primus::Word.new(tokens: tokens)
  end

  def self.build
    gematria_primus = Primus::GematriaPrimus.build
    new(translator: gematria_primus)
  end
end
