RSpec.describe "Primus::Transformations::ReverseLineOrder" do
  describe "#call" do
    {
      "A" => "A",
      "A\n" => "\nA",
      "\nA" => "A\n",
      "\n\nA" => "A\n\n",
      "A\n\n" => "\n\nA",
      "\n" => "\n",
      "A\r\nB\nC" => "C\r\nB\nA",
      "ᚠ-ᚢ.\nᚦ,ᚩ\n" => "\nᚦ,ᚩ\nᚠ-ᚢ.",
    }.each do |source, expected|
      context "with #{source.inspect}" do
        it "reverses content groups including a terminal empty group" do
          builder = Primus::Document::Builder.new(
            pages: [Primus::Page.new(data: source)],
          )
          builder.build

          result = Primus::Transformations::ReverseLineOrder.new.call(
            builder.transcription,
          )

          expect(result.tokens.map(&:lexeme).join).to eq(expected)
        end
      end
    end

    it "keeps original break objects in ordinal order" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "A\r\nB\nC\rD")],
      )
      builder.build
      breaks = builder.transcription.tokens.select { |token|
        token.kind == :line_break
      }

      result = Primus::Transformations::ReverseLineOrder.new.call(
        builder.transcription,
      )

      expect(result.tokens.select { |token| token.kind == :line_break }.
        map(&:object_id)).to eq(breaks.map(&:object_id))
    end

    it "restores leading and trailing empty groups on a second call" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "\nA\r\n\n")],
      )
      builder.build
      operation = Primus::Transformations::ReverseLineOrder.new

      result = operation.call(operation.call(builder.transcription))

      expect([result.tokens.map(&:object_id),
              result.tokens.map(&:lexeme).join]).
        to eq([builder.transcription.tokens.map(&:object_id), "\nA\r\n\n"])
    end

    it "uses current break positions after an entire-sequence reversal" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "A\r\nBC\nD")],
      )
      builder.build
      entire = Primus::Transformations::ReverseEntireSequence.new.call(
        builder.transcription,
      )

      result = Primus::Transformations::ReverseLineOrder.new.call(entire)

      expect(result.tokens.map(&:lexeme).join).to eq("A\nCB\r\nD")
    end

    it "returns a distinct empty transcription for an empty page" do
      builder = Primus::Document::Builder.new(pages: [Primus::Page.new])
      builder.build

      result = Primus::Transformations::ReverseLineOrder.new.call(
        builder.transcription,
      )

      expect([result.equal?(builder.transcription), result.source_bodies,
              result.tokens]).to eq([false, [""], []])
    end
  end
end
