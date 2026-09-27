class Primus::Transformations::PageMapper
  def call(transcription)
    tokens = transcription.pages.each_index.flat_map do |occurrence|
      yield tokens_for(transcription, occurrence)
    end
    Primus::Transcription.new(pages: transcription.pages.dup, tokens: tokens,
                              boundaries: transcription.boundaries.dup)
  end

  private

  def tokens_for(transcription, occurrence)
    transcription.tokens.select do |token|
      token.source_location.occurrence == occurrence
    end
  end
end
