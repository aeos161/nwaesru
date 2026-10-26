class Primus::Experiment::Atbash
  def initialize(parameters)
    @parameters = parameters
  end

  def call(transcription)
    alphabet = Primus::GematriaPrimus.build
    tokens = transcription.tokens.map do |token|
      next token unless token.kind == :rune
      index = alphabet.find_by(rune: token.lexeme).index
      rune = alphabet.find_by(index: @parameters.fetch("modulus") - 1 - index).rune
      Primus::Transcription::Token.new(lexeme: rune, kind: :rune,
                                        source_location: token.source_location)
    end
    Primus::Transcription.new(pages: transcription.pages, tokens: tokens,
                               boundaries: transcription.boundaries)
  end
end
