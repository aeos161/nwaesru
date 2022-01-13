class Primus::TotientShift
  attr_reader :translator

  def initialize(translator:)
    @translator = translator
    @primes = Prime.each.to_enum
    @number_of_characters_processed = 0
    @index_of_untranslatable_character = 56
  end

  def translate(line:)
    line.map { |char| process(character: char) }
  end

  def self.build
    gematria_primus = Primus::GematriaPrimus.build
    new(translator: gematria_primus)
  end

  protected

  attr_reader :primes, :index_of_untranslatable_character
  attr_accessor :number_of_characters_processed

  def process(character:)
    return character unless character.present?
    return character if not_translatable?
    shifted_index = totient_shift(character: character, prime: primes.next)
    increment_characters_processed
    translator.find_by(index: shifted_index)
  end

  def not_translatable?
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
    (character.index - totient(prime)) % translator.size
  end

  def totient(prime)
    prime - 1
  end
end
