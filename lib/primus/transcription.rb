class Primus::Transcription
  attr_reader :pages, :tokens, :boundaries

  def initialize(pages: [], tokens: [], boundaries: [])
    @pages = pages
    @tokens = tokens
    @boundaries = boundaries
  end

  def source_bodies
    pages.map(&:source_body)
  end

  def self.compose(transcriptions)
    pages = transcriptions.flat_map(&:pages)
    tokens = transcriptions.flat_map(&:tokens)
    boundaries = (1...pages.size).map do |occurrence|
      Primus::Transcription::PageBoundary.new(occurrence: occurrence)
    end
    new(pages: pages, tokens: tokens, boundaries: boundaries)
  end
end
