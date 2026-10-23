RSpec.describe Primus::Experiment::Latin do
  def two_page_transcription
    first = Primus::LiberPrimus::Page.new(
      number: 99, data: "ᚱ-ᚷ", source_body: "ᚱ-ᚷ"
    )
    second = Primus::LiberPrimus::Page.new(
      number: 100, data: "ᚦᚦ", source_body: "ᚦᚦ"
    )
    pages = [first, second]
    scans = pages.each_with_index.map do |page, occurrence|
      Primus::Lexer::SourceScan.new(page: page, strategy: :runic,
                                    occurrence: occurrence).to_transcription
    end
    Primus::Transcription.compose(scans)
  end

  describe "#call" do
    it "keeps the existing compatibility line break at a page boundary" do
      transcription = two_page_transcription

      observation = described_class.new.call(transcription)

      expect(observation.output_bytes).to eq("r g\nthth")
    end

    it "takes final rune provenance from the matching page occurrence" do
      transcription = two_page_transcription

      observation = described_class.new.call(transcription)
      source_runes = observation.provenance.map { |item| item.fetch("rune") }

      expect(source_runes).to eq(%w[ᚱ ᚷ ᚦ ᚦ])
    end
  end
end
