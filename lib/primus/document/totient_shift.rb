class Primus::Document::TotientShift < Primus::Document::Decoder
  def initialize(alphabet: nil, modulus: nil, key: nil)
    super
    @key = key || Prime.each.to_enum
  end

  protected

  def decode(character)
    next_prime = key.next
    shifted_index = totient_shift(character: character, prime: next_prime)
    alphabet.find_by(index: shifted_index)
  end

  def totient_shift(character:, prime:)
    (character.index - totient(prime)) % modulus
  end

  def totient(prime)
    prime - 1
  end
end
