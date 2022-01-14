class Primus::CaesarShift
  attr_reader :translator

  def initialize(translator:)
    @translator = translator
  end

  def translate(line:)
    line.map { |char| process(character: char) }
  end

  def self.build
    gematria_primus = Primus::GematriaPrimus.build
    new(translator: gematria_primus)
  end

  protected

  def process(character:)
    #return character unless character.present?
    #shifted_index = fib_shift(character: character) #, n: fibonacci.next)
    #translator.find_by(index: shifted_index)
  rescue => e
    binding.pry
    character
  end
end
