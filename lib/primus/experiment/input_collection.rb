class Primus::Experiment::InputCollection
  attr_reader :sources

  def initialize(selections)
    @sources = selections.each_with_index.map do |selection, occurrence|
      Primus::Experiment::InputSource.new(selection: selection, occurrence: occurrence)
    end.freeze
    freeze
  end

  def source_body
    sources.map(&:body).join.freeze
  end

  def manifest
    offset = 0
    sources.map do |source|
      item = source.manifest(offset)
      offset = item.fetch("byte_end")
      item
    end
  end

  def transcription
    scans = sources.map do |source|
      Primus::Lexer::SourceScan.new(page: source.page, strategy: :runic,
                                    occurrence: source.occurrence).to_transcription
    end
    Primus::Transcription.compose(scans)
  end

  def rune_count
    transcription.tokens.count { |token| token.kind == :rune }
  end
end
