RSpec.describe Primus::Transcription do
  %w[ReverseTokensWithinLines ReverseLineOrder
     ReverseEntireSequence].each do |name|
    context "with #{name}" do
      it "keeps repeated page occurrences separate from an empty middle page" do
        repeated = Primus::LiberPrimus::Page.new(number: 55, data: "ᚠᚢ")
        empty = Primus::LiberPrimus::Page.new(number: 54)
        builder = Primus::Document::Builder.new(pages: [repeated, empty,
                                                        repeated])
        builder.build

        result = Primus::Transformations.const_get(name).new.call(
          builder.transcription,
        )
        bodies = result.pages.each_index.map do |occurrence|
          result.tokens.select { |token|
            token.source_location.occurrence == occurrence
          }.map(&:lexeme).join
        end

        expect(bodies).to eq(["ᚢᚠ", "", "ᚢᚠ"])
      end

      it "preserves page and boundary identity and order" do
        repeated = Primus::Page.new(data: "ᚠᚢ")
        builder = Primus::Document::Builder.new(
          pages: [repeated, Primus::Page.new, repeated],
        )
        builder.build
        source = builder.transcription

        result = Primus::Transformations.const_get(name).new.call(source)

        expect([result.pages.map(&:object_id),
                result.boundaries.map(&:object_id)]).
          to eq([source.pages.map(&:object_id),
                 source.boundaries.map(&:object_id)])
      end

      it "leaves the source bodies and artifact bytes unchanged" do
        artifact = "---\nbody: ᚠᚢ\n"
        page = Primus::Page.new(data: "ᚠᚢ", artifact_bytes: artifact,
                                source_path: "page.yml")
        builder = Primus::Document::Builder.new(pages: [page])
        builder.build

        result = Primus::Transformations.const_get(name).new.call(
          builder.transcription,
        )

        expect([result.source_bodies, result.pages.first.artifact_bytes,
                result.pages.first.source_path]).
          to eq([["ᚠᚢ"], artifact, "page.yml"])
      end

      it "does not alter any source token or its original location object" do
        builder = Primus::Document::Builder.new(
          pages: [Primus::Page.new(data: "ᚠ-ᚢ\n")],
        )
        builder.build
        source = builder.transcription
        original_ids = source.tokens.map(&:object_id)
        location_ids = source.tokens.map { |token|
          token.source_location.object_id
        }

        Primus::Transformations.const_get(name).new.call(source)

        expect([source.tokens.map(&:lexeme).join,
                source.tokens.map(&:object_id),
                source.tokens.map { |token| token.source_location.object_id }]).
          to eq(["ᚠ-ᚢ\n", original_ids, location_ids])
      end

      it "returns new result collections independent of input collections" do
        builder = Primus::Document::Builder.new(
          pages: [Primus::Page.new(data: "ᚠ"), Primus::Page.new(data: "ᚢ")],
        )
        builder.build
        source = builder.transcription

        result = Primus::Transformations.const_get(name).new.call(source)

        expect([result.pages.equal?(source.pages),
                result.tokens.equal?(source.tokens),
                result.boundaries.equal?(source.boundaries)]).
          to eq([false, false, false])
      end

      it "does not expose input arrays to a result collection edit" do
        builder = Primus::Document::Builder.new(
          pages: [Primus::Page.new(data: "ᚠ"), Primus::Page.new(data: "ᚢ")],
        )
        builder.build
        source = builder.transcription

        result = Primus::Transformations.const_get(name).new.call(source)
        result.tokens.clear
        result.pages.clear
        result.boundaries.clear

        expect([source.pages.size, source.tokens.map(&:lexeme),
                source.boundaries.map(&:occurrence)]).to eq([2, ["ᚠ", "ᚢ"],
                                                             [1]])
      end
    end
  end

  describe "external composition" do
    it "uses current token order through two independent operations" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ-ᚢ.\nᚦ,ᚩ\n")],
      )
      builder.build
      within = Primus::Transformations::ReverseTokensWithinLines.new
      lines = Primus::Transformations::ReverseLineOrder.new

      result = lines.call(within.call(builder.transcription))

      expect(result.tokens.map(&:lexeme).join).to eq("\nᚩ,ᚦ\n.ᚢ-ᚠ")
    end

    it "retains no input-specific state between calls" do
      first_builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠᚢ\nᚦ")],
      )
      second_builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚩᚱ")],
      )
      first_builder.build
      second_builder.build
      operation = Primus::Transformations::ReverseLineOrder.new
      original = first_builder.transcription.tokens
      expected_ids = original.values_at(3, 2, 0, 1).map(&:object_id)

      first = operation.call(first_builder.transcription)
      operation.call(second_builder.transcription)
      again = operation.call(first_builder.transcription)

      expect([first.tokens.map(&:object_id), again.tokens.map(&:object_id),
              again.tokens.map(&:lexeme).join]).
        to eq([expected_ids, expected_ids, "ᚦ\nᚠᚢ"])
    end
  end

  describe "explicit Parser reparsing" do
    it "builds new runic sentences from reversed lexical order" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ,ᚢ")],
      )
      builder.build
      transformed = Primus::Transformations::ReverseEntireSequence.new.call(
        builder.transcription,
      )
      parser = Primus::Parser.new(transcription: transformed,
                                  policy: :compatibility, strategy: :runic,
                                  track_delimiters: false)

      parsed = parser.parse

      expect(parsed.sentences.map(&:to_s)).to eq(["ᚢ,", "ᚠ"])
    end

    it "leaves the original Document view unchanged by reparsing" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ,ᚢ")],
      )
      builder.build
      source_document = builder.result
      transformed = Primus::Transformations::ReverseEntireSequence.new.call(
        builder.transcription,
      )

      Primus::Parser.new(transcription: transformed, strategy: :runic).parse

      expect(source_document.to_s(:rune)).to eq("ᚠ,ᚢ")
    end

    it "attaches source locations to new interpreted tokens" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ,ᚢ")],
      )
      builder.build
      transformed = Primus::Transformations::ReverseEntireSequence.new.call(
        builder.transcription,
      )
      parser = Primus::Parser.new(transcription: transformed, strategy: :runic)

      parsed = parser.parse

      expect(parsed.tokens.map { |token| token.source_location.object_id }).
        to eq(builder.transcription.tokens.values_at(2, 0).map { |token|
          token.source_location.object_id
        })
    end

    it "keeps Latin source case with explicit Latin parsing" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ThING")], strategy: :latin,
      )
      builder.build
      transformed = Primus::Transformations::ReverseEntireSequence.new.call(
        builder.transcription,
      )
      parser = Primus::Parser.new(transcription: transformed, strategy: :latin,
                                  policy: :compatibility)

      parser.parse

      expect([transformed.tokens.map(&:lexeme),
              parser.result.tokens.map(&:lexeme)]).
        to eq([["ING", "Th"], ["ing", "th"]])
    end

    it "uses the existing synthetic page separator in the parsed view" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ \n"), Primus::Page.new(data: "ᚢ")],
      )
      builder.build
      transformed = Primus::Transformations::ReverseEntireSequence.new.call(
        builder.transcription,
      )
      parser = Primus::Parser.new(transcription: transformed, strategy: :runic)

      parsed = parser.parse

      expect(parsed.to_s(:rune)).to eq("\n ᚠ\nᚢ")
    end
  end
end
