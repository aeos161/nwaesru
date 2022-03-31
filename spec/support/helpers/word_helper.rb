module WordHelper
  def build_token(rune:, index:, letter:, value:)
    Primus::GematriaPrimus::Token.new(index: index, rune: rune, letter: letter,
                                      value: value)
  end

  def create_word(text)
    alphabet = Primus::GematriaPrimus.build
    tks = Array(text).map(&:downcase).map { |tk| alphabet.find_by(letter: tk) }
    Primus::Word.new(tokens: tks)
  end
end
