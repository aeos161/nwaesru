RSpec.describe Primus::Experiment::Atbash do
  def transcription(body)
    page = Primus::LiberPrimus::Page.new(number: 99, data: body, source_body: body)
    Primus::Lexer::SourceScan.new(page: page, strategy: :runic).to_transcription
  end

  def operation
    described_class.new("alphabet" => "gematria-primus", "modulus" => 29)
  end

  describe "#call" do
    it "substitutes GP indices using 28 minus the current index" do
      source = transcription("ᚠ-ᚢ\nᚦ.ᛠ")

      result = operation.call(source)

      expect(result.tokens.map(&:lexeme).join).to eq("ᛠ-ᛡ\nᚣ.ᚠ")
    end

    it "retains non-rune tokens and their lexical order" do
      source = transcription("ᚠ-0xA?\r\nᚢ@ᚦ.")

      result = operation.call(source)

      expect(result.tokens.reject { |token| token.kind == :rune }.map(&:lexeme)).to eq(
        ["-", "0", "x", "A", "?", "\r\n", "@", "."]
      )
    end

    it "retains source coordinates on substituted runes" do
      source = transcription("ᚠ-ᚢ\nᚦ")

      result = operation.call(source)

      expect(result.tokens.select { |token| token.kind == :rune }.map(&:source_location)).to eq(
        source.tokens.select { |token| token.kind == :rune }.map(&:source_location)
      )
    end

    it "leaves its input tokens unchanged" do
      source = transcription("ᚠ-ᚢ")

      operation.call(source)

      expect(source.tokens.map(&:lexeme).join).to eq("ᚠ-ᚢ")
    end

    it "returns the exact source after a second Atbash step" do
      source = transcription("ᚠ-ᚢ\r\nᚦ.")

      twice = operation.call(operation.call(source))

      expect(twice.tokens.map(&:lexeme).join).to eq("ᚠ-ᚢ\r\nᚦ.")
    end
  end
end
