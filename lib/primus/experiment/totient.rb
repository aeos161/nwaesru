class Primus::Experiment::Totient
  def initialize(parameters)
    @parameters = parameters
  end

  def call(transcription)
    runes = transcription.tokens.select { |token| token.kind == :rune }
    shifted = shift.visit_word(Primus::Word.new(tokens: runes.map { |token|
      Primus::GematriaPrimus.build.find_by(rune: token.lexeme)
    })).tokens
    replacements = shifted.each
    tokens = transcription.tokens.map do |token|
      token.kind == :rune ? replace(token, replacements.next.rune) : token
    end
    Primus::Transcription.new(pages: transcription.pages, tokens: tokens,
                               boundaries: transcription.boundaries)
  end

  private

  def shift
    primes = Prime.each.lazy.drop_while { |prime| prime < @parameters.fetch("prime_start") }
    Primus::Document::TotientShift.new(
      modulus: @parameters.fetch("modulus"), key: primes
    ).tap { |visitor| visitor.skip_sequence = @parameters.fetch("skip_sequence") }
  end

  def replace(token, rune)
    Primus::Transcription::Token.new(lexeme: rune, kind: :rune,
                                      source_location: token.source_location)
  end
end
