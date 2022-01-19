class Primus::Document::Vigenere
  attr_reader :alphabet, :key, :modulus

  def initialize(alphabet: nil, key:, modulus: nil, interrupter_sequence: [])
    @alphabet = alphabet || Primus::GematriaPrimus.build
    @key = key.split("").map { |l| @alphabet.find_by(letter: l) }.to_enum
    @modulus = modulus || @alphabet.size
    @number_of_characters_processed = 0
    @current_key_character = nil
    @interrupter_sequence = interrupter_sequence
  end

  def visit_word(word)
    tokens = word.map { |char| process(character: char) }
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end

  protected

  attr_reader :interrupter_sequence
  attr_accessor :number_of_characters_processed

  def interrupter?
    true if interrupter_sequence.include? number_of_characters_processed
  end

  def process(character:)
    return character if character.index.nil?
    decoded_character = decode(character)
    increment_characters_processed
    decoded_character
  end

  def decode(character)
    if interrupter?
      character
    else
      plain_text_index = (character.index - next_key_letter.index) % modulus
      alphabet.find_by(index: plain_text_index)
    end
  end

  def next_key_letter
    @current_key_character = key.next
  rescue StopIteration
    key.rewind
    @current_key_character = key.next
  end

  def increment_tokens_processed
    self.number_of_tokens_processed += 1
  end

  def increment_characters_processed
    self.number_of_characters_processed += 1
  end
end
