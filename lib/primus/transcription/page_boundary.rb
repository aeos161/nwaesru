class Primus::Transcription::PageBoundary
  attr_reader :occurrence

  def initialize(occurrence:)
    @occurrence = occurrence
  end
end
