RSpec.describe "Primus::Transformations::ReverseEntireSequence" do
  describe "#call" do
    it "reverses every token including line breaks and marks" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ-ᚢ.\nᚦ,ᚩ\n")],
      )
      builder.build

      result = Primus::Transformations::ReverseEntireSequence.new.call(
        builder.transcription,
      )

      expect(result.tokens.map(&:lexeme).join).to eq("\nᚩ,ᚦ\n.ᚢ-ᚠ")
    end

    it "reverses CRLF as one token and retains a lone CR" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "A\r\nB\rC")],
      )
      builder.build

      result = Primus::Transformations::ReverseEntireSequence.new.call(
        builder.transcription,
      )

      expect(result.tokens.map(&:lexeme)).to eq(["C", "\r", "B", "\r\n", "A"])
    end

    it "retains original Latin lexemes and spans after reversal" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ThING")], strategy: :latin,
      )
      builder.build

      result = Primus::Transformations::ReverseEntireSequence.new.call(
        builder.transcription,
      )
      lexemes_and_spans = result.tokens.map do |token|
        location = token.source_location
        [token.lexeme, location.character_start, location.character_end]
      end

      expect(lexemes_and_spans).to eq([["ING", 2, 5], ["Th", 0, 2]])
    end

    it "does not merge Latin tokens made adjacent by reversal" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "HT")], strategy: :latin,
      )
      builder.build

      result = Primus::Transformations::ReverseEntireSequence.new.call(
        builder.transcription,
      )

      expect(result.tokens.map(&:lexeme)).to eq(["T", "H"])
    end

    it "retains every original token object once across diverse marks" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ᛫᛬'\"\t 🙂ᚢ")],
      )
      builder.build
      original_ids = builder.transcription.tokens.map(&:object_id)

      result = Primus::Transformations::ReverseEntireSequence.new.call(
        builder.transcription,
      )

      expect(result.tokens.map(&:object_id)).to eq(original_ids.reverse)
    end

    it "keeps byte, character, line, column, and rune coordinates original" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::LiberPrimus::Page.new(number: 55, data: "ᚠ-ᚢ\r\nA")],
      )
      builder.build

      result = Primus::Transformations::ReverseEntireSequence.new.call(
        builder.transcription,
      )
      coordinates = result.tokens.map do |token|
        location = token.source_location
        [location.page_number, location.occurrence, location.byte_start,
         location.byte_end, location.character_start, location.character_end,
         location.line, location.column, location.rune_index]
      end

      expect(coordinates).to eq(
        [[55, 0, 9, 10, 5, 6, 1, 0, nil],
         [55, 0, 7, 9, 3, 5, 0, 3, nil],
         [55, 0, 4, 7, 2, 3, 0, 2, 1],
         [55, 0, 3, 4, 1, 2, 0, 1, nil],
         [55, 0, 0, 3, 0, 1, 0, 0, 0]],
      )
    end

    it "restores the same token objects and bytes on a second call" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ\r\n\tᚢ᛫᛬\r")],
      )
      builder.build
      operation = Primus::Transformations::ReverseEntireSequence.new

      result = operation.call(operation.call(builder.transcription))

      expect([result.tokens.map(&:object_id),
              result.tokens.map(&:lexeme).join]).
        to eq([builder.transcription.tokens.map(&:object_id), "ᚠ\r\n\tᚢ᛫᛬\r"])
    end
  end
end
