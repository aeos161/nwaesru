class Primus::Document::Atbash
  attr_reader :alphabet, :modulus

  def initialize(alphabet: nil, modulus: nil)
    @alphabet = alphabet || Primus::GematriaPrimus.build
    @modulus = modulus || @alphabet.size
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
    alphabet.find_by(index: new_position)
  end

  def gematria_shift(position:)
    (-1 * (position + 1)) % modulus
  end
end
