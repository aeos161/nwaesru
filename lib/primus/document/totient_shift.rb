class Primus::Document::TotientShift
  attr_reader :alphabet, :modulus

  def initialize(alphabet: nil, primes: nil, modulus: nil,
                 number_of_characters_processed: 0,
                 interrupter_sequence: [])
    @alphabet = alphabet || Primus::GematriaPrimus.build
    @primes = primes || Prime.each.to_enum
    @number_of_characters_processed = number_of_characters_processed
    @interrupter_sequence = interrupter_sequence
    @modulus = modulus || @alphabet.size
  end

  def visit_word(word)
    tokens = word.map { |char| process(character: char) }
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end

  protected

  attr_reader :primes, :interrupter_sequence
  attr_accessor :number_of_characters_processed

  def not_shiftable?(character)
    character.index.nil?
  end

  def interrupter?
    true if interrupter_sequence.include? number_of_characters_processed
  end

  def process(character:)
    return character if not_shiftable?(character)
    decoded_character = decode(character)
    increment_characters_processed
    decoded_character
  end

  def decode(character)
    if interrupter?
      character
    else
      shifted_index = totient_shift(character: character, prime: primes.next)
      alphabet.find_by(index: shifted_index)
    end
  end

  def totient_shift(character:, prime:)
    (character.index - totient(prime)) % modulus
  end

  def totient(prime)
    prime - 1
  end

  def increment_characters_processed
    self.number_of_characters_processed += 1
  end
end
