class Primus::AlternatingShift
  attr_reader :translator

  def initialize(translator:, shifts: [13, 7, 5, 13, 7, 5, 15, 15])
    @translator = translator
    @number_of_characters_processed = 0
    @number_of_words_processed = 0
    @shifts = shifts
  end

  def translate(line:)
    binding.pry
    #line.map { |char| process(character: char) }
    #@number_of_lines_processed += 1
  end

  def self.build
    gematria_primus = Primus::GematriaPrimus.build
    new(translator: gematria_primus)
  end

  protected

  attr_accessor :number_of_characters_processed, :shifts

  def process(character:)
    return character unless character.present?
    shifted_index = alternating_shift(character: character)
    increment_characters_processed
    translator.find_by(index: shifted_index)
  end

  def alternating_shift(character:)
    (character.index + shift_by) % translator.size
  end

  def shift_by
    shifts[number_of_characters_processed % shifts.size]
  end

  def increment_characters_processed
    self.number_of_characters_processed += 1
  end
end
