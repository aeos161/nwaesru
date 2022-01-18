class Primus::Document::Vigenere
  attr_reader :alphabet, :key, :modulus

  def initialize(alphabet: nil, key:, modulus: nil)
    @alphabet = alphabet || Primus::GematriaPrimus.build
    @key = key.split("").map { |l| @alphabet.find_by(letter: l) }.to_enum
    @modulus = modulus || @alphabet.size
    @number_of_characters_processed = 0
    @current_key_character = nil
    @interrupter_sequence = [48, 74, 84, 132, 159, 160, 250]
  end

  def visit_word(word)
    tokens = word.map { |char| process(character: char) }
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end

  protected

  attr_accessor :number_of_characters_processed, :interrupter_sequence

  def interrupter?
    true if interrupter_sequence.include? number_of_characters_processed
  end

  def process(character:)
    return character if character.index.nil?
    if interrupter?
      increment_characters_processed
      character
    else
      plain_text_index = (character.index - next_key_letter.index) % modulus
      increment_characters_processed
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
