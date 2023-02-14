class Primus::Document::KeyFinder
  attr_reader :cipher_text

  def initialize(cipher_text:)
    @cipher_text = cipher_text
  end

  def find(plain_text:)
    cipher_text - plain_text
  end

  def self.build(cipher_text, reverse: false, parser: :letter)
    cipher_text = Primus.parse(cipher_text, parser.to_sym).first
    if reverse
      cipher_text = cipher_text.reverse
    end
    new(cipher_text: cipher_text)
  end
end
