class Primus::Document::Atbash < Primus::Document::Affine
  def initialize(alphabet: nil, modulus: nil)
    alphabet ||= Primus::GematriaPrimus.build
    modulus ||= alphabet.size
    key = modulus - 1
    super(alphabet: alphabet, key: key, magnitude: key, modulus: modulus)
  end
end
