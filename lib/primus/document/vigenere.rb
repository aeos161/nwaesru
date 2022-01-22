class Primus::Document::Vigenere < Primus::Document::Decoder
  def initialize(alphabet: nil, modulus: nil, key: nil)
    super
    if key.respond_to? :split
      key = key.split("")
    end
    @key = key.map { |l| @alphabet.find_by(letter: l) }.to_enum
    @current_key_character = nil
  end

  protected

  def decode(character)
    plain_text_index = (character.index - next_key_letter.index) % modulus
    alphabet.find_by(index: plain_text_index)
  rescue => e
    puts "----"
    puts "KEY: #{key.inspect}"
    puts "CHAR: #{character.inspect}"
    puts e.inspect
    puts "---"
  end

  def next_key_letter
    @current_key_character = key.next
  rescue StopIteration
    key.rewind
    @current_key_character = key.next
  end
end
