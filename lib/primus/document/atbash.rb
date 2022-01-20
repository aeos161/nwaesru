class Primus::Document::Atbash < Primus::Document::Decoder

  protected

  def decode(character)
    current_position = character.index
    new_position = gematria_shift(position: current_position)
    alphabet.find_by(index: new_position)
  end

  def gematria_shift(position:)
    (-1 * (position + 1)) % modulus
  end
end
