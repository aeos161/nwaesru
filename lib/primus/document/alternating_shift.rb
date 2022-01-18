class Primus::Document::AlternatingShift
  attr_reader :dictionary

  def initialize(dictionary: nil, shifts: [1, 1, 2, 9])
    @dictionary = dictionary || Primus::GematriaPrimus.build
    @number_of_characters_processed = 0
    @number_of_words_processed = 0
    @shifts = shifts
  end

  def visit_word(word)
    tokens= word.map { |char| process(character: char) }
    word = Primus::Word.new(tokens: tokens)
    @number_of_words_processed += 1
    @number_of_characters_processed += word.size
    word
  end

  def visit_token(token)
    token
  end

  protected

  attr_accessor :number_of_characters_processed, :shifts

  def process(character:)
    return character if character.index.nil?
    shifted_index = alternating_shift(character: character)
    increment_characters_processed
    dictionary.find_by(index: shifted_index)
  end

  def alternating_shift(character:)
    (character.index + shift_by) % dictionary.size
  end

  def shift_by
    shifts[number_of_characters_processed % shifts.size]
  end

  def increment_characters_processed
    self.number_of_characters_processed += 1
  end
end
