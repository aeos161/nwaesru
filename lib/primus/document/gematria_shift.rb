class Primus::Document::GematriaShift
  attr_reader :dictionary

  def initialize(dictionary: nil)
    @dictionary = dictionary || Primus::GematriaPrimus.build
  end

  def visit_word(word)
    tokens = word.map { |char| process(character: char) }
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end

  protected

  def process(character:)
    return character if character.index.nil?
    current_position = character.index
    new_position = gematria_shift(position: current_position)
    dictionary.find_by(index: new_position)
  end

  def gematria_shift(position:)
    dictionary.size - (position + 1)
  end
end
