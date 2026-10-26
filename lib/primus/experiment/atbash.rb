class Primus::Experiment::Atbash
  def initialize(parameters)
    @modulus = parameters.fetch("modulus")
  end

  def call(transcription)
    tokens = transcription.tokens.map { |token| mirrored_token(token) }
    Primus::Transcription.new(pages: transcription.pages, tokens: tokens,
                               boundaries: transcription.boundaries)
  end

  private

  def mirrored_token(token)
    return token unless token.kind == :rune
    Primus::Transcription::Token.new(lexeme: mirrored_rune(token.lexeme),
                                      kind: :rune, source_location: token.source_location)
  end

  def mirrored_rune(rune)
    alphabet = Primus::GematriaPrimus.build
    index = alphabet.find_by(rune: rune).index
    alphabet.find_by(index: @modulus - 1 - index).rune
  end
end
