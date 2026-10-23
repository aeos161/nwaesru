RSpec.describe Primus::Experiment::RuneReversal do
  def transcription(body, number: 99, occurrence: 0)
    page = Primus::LiberPrimus::Page.new(number: number, data: body, source_body: body)
    Primus::Lexer::SourceScan.new(page: page, strategy: :runic,
                                  occurrence: occurrence).to_transcription
  end

  def operation
    described_class.new("scope" => "composed-input", "non_runes" => "fixed")
  end

  describe "#call" do
    it "reverses rune tokens over fixed punctuation and uneven lines" do
      source = transcription("ᚠ-ᚢ\nᚦ.")

      result = operation.call(source)

      expect(result.tokens.map(&:lexeme).join).to eq("ᚦ-ᚢ\nᚠ.")
    end

    it "keeps hexadecimal text, unknown characters, and CRLF in their slots" do
      source = transcription("ᚠ-0xA?\r\nᚢ@ᚦ.")

      result = operation.call(source)

      expect(result.tokens.map(&:lexeme).join).to eq("ᚦ-0xA?\r\nᚢ@ᚠ.")
    end

    it "permutes across source occurrences without swapping page blocks" do
      first = transcription("ᚠ-ᚢ", number: 99)
      second = transcription("ᚦ.", number: 100, occurrence: 1)
      source = Primus::Transcription.compose([first, second])

      result = operation.call(source)

      expect(result.tokens.map(&:lexeme).join).to eq("ᚦ-ᚢᚠ.")
    end

    it "carries source occurrence and rune index with a cross-page rune" do
      first = transcription("ᚠ-ᚢ", number: 99)
      second = transcription("ᚦ.", number: 100, occurrence: 1)
      source = Primus::Transcription.compose([first, second])

      result = operation.call(source)
      locations = result.tokens.select { |token| token.kind == :rune }
                        .map { |token| token.source_location }

      expect(locations.map { |item| [item.page_number, item.occurrence, item.rune_index] }).to eq(
        [[100, 1, 0], [99, 0, 1], [99, 0, 0]]
      )
    end

    it "keeps repeated pages distinct by occurrence" do
      first = transcription("ᚠ", number: 99)
      second = transcription("ᚦ", number: 99, occurrence: 1)
      source = Primus::Transcription.compose([first, second])

      result = operation.call(source)
      occurrences = result.tokens.map { |token| token.source_location.occurrence }

      expect(occurrences).to eq([1, 0])
    end

    it "returns an empty transcription for empty operation input" do
      source = transcription("")

      result = operation.call(source)

      expect(result.tokens).to eq([])
    end

    it "retains a singleton rune in its original slot" do
      source = transcription("?ᚠ.")

      result = operation.call(source)

      expect(result.tokens.map(&:lexeme).join).to eq("?ᚠ.")
    end

    it "restores exact bytes and source coordinates after two reversals" do
      source = transcription("ᚠ-ᚢ\r\nᚦ.")

      twice = operation.call(operation.call(source))
      signature = twice.tokens.map { |token| [token.lexeme, token.kind, token.source_location] }

      expect(signature).to eq(
        source.tokens.map { |token| [token.lexeme, token.kind, token.source_location] }
      )
    end

    it "does not mutate the source token order" do
      source = transcription("ᚠ-ᚢ\nᚦ.")

      operation.call(source)

      expect(source.tokens.map(&:lexeme).join).to eq("ᚠ-ᚢ\nᚦ.")
    end
  end
end
