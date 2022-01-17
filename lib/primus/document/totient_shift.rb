class Primus::Document::TotientShift
  attr_reader :dictionary

  def initialize(dictionary: nil, primes: nil, modulus: 29,
                 number_of_characters_processed: 0)
    @dictionary = dictionary || Primus::GematriaPrimus.build
    @primes = primes || Prime.each.to_enum
    @number_of_characters_processed = number_of_characters_processed
    @index_of_untranslatable_character = 56
    @modulus = modulus || 29
  end

  def visit_word(word)
    tokens = word.map { |char| process(character: char) }
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end

  protected

  attr_reader :modulus, :primes, :index_of_untranslatable_character
  attr_accessor :number_of_characters_processed

  def process(character:)
    return character if not_shiftable?(character)
    return character if character_to_skip?
    shifted_index = totient_shift(character: character, prime: primes.next)
    increment_characters_processed
    dictionary.find_by(index: shifted_index)
  end

  def not_shiftable?(character)
    character.index.nil?
  end

  def character_to_skip?
    if number_of_characters_processed == index_of_untranslatable_character
      increment_characters_processed
      true
    else
      false
    end
  end

  def increment_characters_processed
    self.number_of_characters_processed += 1
  end

  def totient_shift(character:, prime:)
    (character.index - totient(prime)) % modulus
  end

  def totient(prime)
    prime - 1
  end
end
