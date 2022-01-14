class Primus::GematriaShift
  attr_reader :translator

  def initialize(translator:)
    @translator = translator
  end

  def translate(word:)
    Primus::LiberPrimus::Word.new(
      tokens: word.map { |char| process(character: char) }
    )
  end

  def self.build
    gematria_primus = Primus::GematriaPrimus.build
    new(translator: gematria_primus)
  end

  protected

  def process(character:)
    return character unless character.present?
    current_position = character.index
    new_position = gematria_shift(position: current_position)
    translator.find_by(index: new_position)
  end

  def gematria_shift(position:)
    translator.size - (position + 1)
  end
end
