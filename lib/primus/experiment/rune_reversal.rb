class Primus::Experiment::RuneReversal
  def initialize(parameters)
    @parameters = parameters
  end

  def call(transcription)
    runes = transcription.tokens.select { |token| token.kind == :rune }.reverse.each
    tokens = transcription.tokens.map { |token| token.kind == :rune ? runes.next : token }
    Primus::Transcription.new(pages: transcription.pages, tokens: tokens,
                               boundaries: transcription.boundaries)
  end
end
