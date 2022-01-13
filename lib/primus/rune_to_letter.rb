class Primus::RuneToLetter
  attr_reader :translator

  def initialize(translator:)
    @translator = translator
  end

  def translate(line:)
    line.
      split("").
      map { |rune| translator.find_translation(rune: rune) }
  end

  def self.build
    gematria_primus = Primus::GematriaPrimus.build
    new(translator: gematria_primus)
  end
end
