class Primus::FibonacciShift
  attr_reader :translator

  def initialize(translator:)
    @translator = translator
    @fibonacci = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233].to_enum
      #.select { |n| Prime.prime? n }
  end

  def translate(line:)
    line.map { |char| process(character: char) }
  end

  def self.build
    gematria_primus = Primus::GematriaPrimus.build
    new(translator: gematria_primus)
  end

  protected

  attr_reader :fibonacci

  def process(character:)
    return character unless character.present?
    shifted_index = fib_shift(character: character, n: fibonacci.next)
    translator.find_by(index: shifted_index)
  rescue
    character
  end

  def fib_shift(character:, n:)
    (character.index + n) % translator.size
  end
end
