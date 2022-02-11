class Primus::Document::CaesarShift < Primus::Document::Affine
  def initialize(alphabet: nil, key:, modulus: nil)
    super(alphabet: alphabet, key: key, modulus: modulus, magnitude: 1)
  end
end
