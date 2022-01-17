class Primus::Document::ComplementShift
  attr_reader :dictionary

  def initialize(dictionary: nil)
    @dictionary = dictionary || Primus::GematriaPrimus.build
  end

  def visit_word(word)
    tokens = word.map { |char| process(character: char) }
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end

  protected

  def process(character:)
    return character if character.index.nil?
    shifted_index = flip_bits(character.index)
    dictionary.find_by(index: shifted_index)
  end

  def flip_bits(number)
    bit_flipper = Proc.new { |bit| bit == "1" ? "0" : "1" }
    number.to_s(2).split("").map(&bit_flipper).join.to_i(2) % 29
  end
end
