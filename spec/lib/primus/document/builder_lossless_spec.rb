RSpec.describe Primus::Document::Builder do
  describe "#build" do
    it "composes source bodies without inventing a newline" do
      pages = [Primus::LiberPrimus::Page.new(number: 54, data: "ᚠ"),
               Primus::LiberPrimus::Page.new(number: 55, data: "ᚢ")]
      builder = Primus::Document::Builder.new(pages: pages)

      builder.build
      transcription = builder.transcription

      expect(transcription.source_bodies).to eq(["ᚠ", "ᚢ"])
    end

    it "records the page boundary without adding it to source lexemes" do
      pages = [Primus::Page.new(data: "ᚠ"), Primus::Page.new(data: "ᚢ")]
      builder = Primus::Document::Builder.new(pages: pages)

      builder.build
      transcription = builder.transcription

      expect([transcription.boundaries.size,
              transcription.tokens.map(&:lexeme)]).to eq([1, ["ᚠ", "ᚢ"]])
    end

    it "preserves empty pages and distinct repeated page occurrences" do
      page = Primus::LiberPrimus::Page.new(number: 55, data: "ᚠ")
      pages = [page, Primus::LiberPrimus::Page.new(number: 54), page]
      builder = Primus::Document::Builder.new(pages: pages)

      builder.build
      transcription = builder.transcription
      occurrences = transcription.tokens.map { |token|
        token.source_location.occurrence
      }

      expect([transcription.source_bodies, occurrences]).
        to eq([["ᚠ", "", "ᚠ"], [0, 2]])
    end

    it "keeps original page coordinates separate from chapter positions" do
      pages = [Primus::LiberPrimus::Page.new(number: 54, data: "ᚠ"),
               Primus::LiberPrimus::Page.new(number: 55, data: "ᚢ")]
      builder = Primus::Document::Builder.new(pages: pages)

      builder.build
      token = builder.result[1]

      expect(token.source_location).to have_attributes(
        page_number: 55, occurrence: 1, rune_index: 0,
        byte_start: 0, character_start: 0, line: 0, column: 0
      )
    end

    it "applies inter-page trimming only in the compatibility display" do
      pages = [Primus::LiberPrimus::Page.new(number: 54, data: "ᚠ \n\n"),
               Primus::LiberPrimus::Page.new(number: 55, data: "ᚢ\n")]
      builder = Primus::Document::Builder.new(pages: pages)

      builder.build
      view = builder.result.to_s(:rune)
      sources = builder.transcription.source_bodies

      expect([view, sources]).to eq(["ᚠ\nᚢ", ["ᚠ \n\n", "ᚢ\n"]])
    end

    it "builds an empty source without phantom words or sentences" do
      builder = Primus::Document::Builder.new(pages: [])

      builder.build
      document = builder.result

      expect([builder.transcription.source_bodies,
              document.words.size, document.sentences.size]).to eq([[], 0, 0])
    end

    it "does not append duplicate content on a repeated build" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ-ᚢ.")],
      )
      builder.build

      builder.build

      expect(builder.result.to_s(:rune)).to eq("ᚠ-ᚢ.")
    end

    it "retains legacy document reversal for source-backed words" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ-ᚢ")],
      )

      builder.build
      reversed = builder.result.reverse

      expect(reversed.to_s(:rune)).to eq("ᚢ-ᚠ")
    end

    it "compares equal original coordinates from independent builds" do
      first = Primus::Document::Builder.new(
        pages: [Primus::LiberPrimus::Page.new(number: 55, data: "ᚠ")],
      )
      second = Primus::Document::Builder.new(
        pages: [Primus::LiberPrimus::Page.new(number: 55, data: "ᚠ")],
      )

      first.build
      second.build
      first_location = first.transcription.tokens.first.source_location
      second_location = second.transcription.tokens.first.source_location

      expect(first_location).to eq(second_location)
    end

    it "distinguishes repeated page occurrences in source equality" do
      page = Primus::LiberPrimus::Page.new(number: 55, data: "ᚠ")
      builder = Primus::Document::Builder.new(pages: [page, page])

      builder.build
      locations = builder.transcription.tokens.map(&:source_location)

      expect(locations.first).not_to eq(locations.last)
    end

    it "distinguishes two spans on the same page in source equality" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::LiberPrimus::Page.new(number: 55, data: "ᚠᚠ")],
      )

      builder.build
      locations = builder.transcription.tokens.map(&:source_location)

      expect(locations.first).not_to eq(locations.last)
    end
  end
end
