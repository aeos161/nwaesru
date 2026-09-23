RSpec.describe "Primus::Transformations::ReverseTokensWithinLines" do
  describe "#call" do
    it "reverses all marks within each current line" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ-ᚢ.\nᚦ,ᚩ\n")],
      )
      builder.build

      result = Primus::Transformations::ReverseTokensWithinLines.new.call(
        builder.transcription,
      )

      expect(result.tokens.map(&:lexeme).join).to eq(".ᚢ-ᚠ\nᚩ,ᚦ\n")
    end

    it "preserves the ordinal identity of line breaks across mixed styles" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ\r\nᚢ\rᚦ\n")],
      )
      builder.build
      breaks = builder.transcription.tokens.select { |token|
        token.kind == :line_break
      }

      result = Primus::Transformations::ReverseTokensWithinLines.new.call(
        builder.transcription,
      )

      expect(result.tokens.select { |token| token.kind == :line_break }).
        to eq(breaks)
    end

    it "keeps a Latin multiletter symbol atomic" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ThING")], strategy: :latin,
      )
      builder.build

      result = Primus::Transformations::ReverseTokensWithinLines.new.call(
        builder.transcription,
      )

      expect(result.tokens.map(&:lexeme)).to eq(["ING", "Th"])
    end

    it "reverses current groups after an entire reversal" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠᚢ\nᚦᚩ")],
      )
      builder.build
      entire = Primus::Transformations::ReverseEntireSequence.new.call(
        builder.transcription,
      )

      result = Primus::Transformations::ReverseTokensWithinLines.new.call(entire)

      expect(result.tokens.map(&:lexeme).join).to eq("ᚦᚩ\nᚠᚢ")
    end

    it "restores token identity and exact bytes on a second call" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ\r\n\t ?ᚢ\n")],
      )
      builder.build
      operation = Primus::Transformations::ReverseTokensWithinLines.new

      result = operation.call(operation.call(builder.transcription))

      expect([result.tokens.map(&:object_id),
              result.tokens.map(&:lexeme).join]).
        to eq([builder.transcription.tokens.map(&:object_id), "ᚠ\r\n\t ?ᚢ\n"])
    end

    it "returns a separate empty transcription for zero pages" do
      input = Primus::Transcription.new

      result = Primus::Transformations::ReverseTokensWithinLines.new.call(input)

      expect([result.equal?(input), result.pages, result.tokens,
              result.boundaries]).
        to eq([false, [], [], []])
    end
  end
end
