class Primus::Document::Affine
  attr_reader :alphabet, :key, :modulus, :magnitude

  def initialize(alphabet: nil, key:, modulus: nil, magnitude:)
    @alphabet = alphabet || Primus::GematriaPrimus.build
    @modulus = modulus || @alphabet.size
    @key = key
    @magnitude = magnitude
  end

  def visit_word(word)
    assert_key_and_magnitude_are_co_prime!
    tokens = word.map { |char| process(character: char) }
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end

  protected

  def assert_key_and_magnitude_are_co_prime!
    gcd = key.gcd(magnitude)
    fail "#{key} and #{magnitude} are not co-prime" unless gcd == 1
  end

  def process(character:)
    return character if character.index.nil?
    decode(character)
  end

  def decode(character)
    index = (modinv.index(1) * (character.index - magnitude)) % modulus
    alphabet.find_by(index: index)
  end

  def modinv
    0.upto(modulus - 1).map { |b| (key * b) % modulus }
  end
end
