class Primus::Document::CaesarShift < Primus::Document::Affine
  def initialize(alphabet: nil, key:, modulus: nil, magnitude: 1)
    super
    @magnitude = 1
  end
end
