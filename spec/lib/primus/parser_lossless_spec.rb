RSpec.describe Primus::Parser do
  describe "#parse" do
    it "interprets runic comma as a sentence boundary" do
      transcription = transcription_for("ᚠ,ᚢ")
      parser = Primus::Parser.new(transcription: transcription,
                                  policy: :compatibility)

      parser.parse
      sentences = parser.result.sentences.map(&:to_s)

      expect(sentences).to eq(["ᚠ,", "ᚢ"])
    end

    it "renders generic punctuation without losing source characters" do
      transcription = transcription_for("ᚠ'ᚢ᛫᛬ᚦ")
      parser = Primus::Parser.new(transcription: transcription,
                                  policy: :compatibility)

      parser.parse

      expect(parser.result.to_s(:rune)).to eq("ᚠ'ᚢ᛫᛬ᚦ")
    end

    it "excludes generic punctuation from the word token projection" do
      transcription = transcription_for("ᚠ'ᚢ᛫᛬ᚦ")
      parser = Primus::Parser.new(transcription: transcription,
                                  policy: :compatibility)

      parser.parse
      runes = parser.result.tokens.map { |token| token.to_s(:rune) }

      expect(runes).to eq(["ᚠ", "ᚢ", "ᚦ"])
    end

    it "retains word continuation across a physical line" do
      transcription = transcription_for("ᚠ\nᚢ")
      parser = Primus::Parser.new(transcription: transcription,
                                  policy: :compatibility)

      parser.parse
      words = parser.result.words.map { |word| word.to_s(:rune) }

      expect(words).to eq(["ᚠ\nᚢ"])
    end

    it "flushes terminal delimiters once without an empty sentence" do
      transcription = transcription_for("ᚠ.\n\n")
      parser = Primus::Parser.new(transcription: transcription,
                                  policy: :compatibility)

      parser.parse
      sentences = parser.result.sentences.map(&:to_s)

      expect(sentences).to eq(["ᚠ."])
    end

    it "leaves exact lexical bytes untouched by parsing and rendering" do
      transcription = transcription_for("ᚠ'ᚢ.\n\n")
      parser = Primus::Parser.new(transcription: transcription,
                                  policy: :compatibility)

      parser.parse
      parser.result.to_s
      source = transcription.tokens.map(&:lexeme).join

      expect(source).to eq("ᚠ'ᚢ.\n\n")
    end

    it "builds independent graphs on repeated parsing" do
      transcription = transcription_for("ᚠ-ᚢ.")
      parser = Primus::Parser.new(transcription: transcription,
                                  policy: :compatibility)
      parser.parse
      first = parser.result

      parser.parse
      parser.result.words.first.tokens.clear

      expect(first.to_s(:rune)).to eq("ᚠ-ᚢ.")
    end
  end

  def transcription_for(body)
    lexer = Primus::Lexer.build(page: Primus::Page.new(data: body))
    lexer.tokenize
    lexer.transcription
  end
end
