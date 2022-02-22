class Primus::Document::Vigenere < Primus::Document::Decoder
  def initialize(alphabet: nil, modulus: nil, key: nil, direction: :-)
    super(alphabet: alphabet, modulus: modulus, key: key)
    if key.respond_to? :split
      key = key.split("")
    end
    @key = key.map { |l| @alphabet.find_by(letter: l) }.to_enum
    @direction = direction || :-
    @current_key_character = nil
  end

  protected

  def decode(character)
    key_char = next_key_letter
    character >> key_char
  end

  def next_key_letter
    @current_key_character = key.next
  rescue StopIteration
    key.rewind
    @current_key_character = key.next
  end

  protected

  attr_reader :direction
end
