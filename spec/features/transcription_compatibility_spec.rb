RSpec.describe "transcription compatibility" do
  describe "Document views" do
    it "retains word-oriented tokens without sentence delimiters" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ-ᚢ.ᚦ")],
      )

      builder.build
      runes = builder.result.tokens.map { |token| token.to_s(:rune) }

      expect(runes).to eq(["ᚠ", "ᚢ", "ᚦ"])
    end

    it "retains existing sentence boundaries" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ-ᚢ.ᚦ")],
      )

      builder.build
      sentences = builder.result.sentences.map(&:to_s)

      expect(sentences).to eq(["ᚠ-ᚢ.", "ᚦ"])
    end

    it "looks up rune positions independently of delimiters" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ-ᚢ.ᚦ")],
      )

      builder.build
      result = builder.result[2].to_s(:rune)

      expect(result).to eq("ᚦ")
    end

    it "keeps ngram input free of sentence delimiters" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::Page.new(data: "ᚠ-ᚢ.ᚦ-ᚩ")],
      )
      builder.build
      document = builder.result.accept(Primus::Document::Translator.new)
      converter = Primus::Document::NgramConverter.new(document: document)

      converter.convert
      result = converter.result.to_s

      expect(result).to eq("f.u th.o")
    end
  end

  describe "Primus helpers" do
    it "maps multiletter GP symbols in to_word" do
      text = "thing"

      result = Primus.to_word(text).tokens.map(&:rune)

      expect(result).to eq(["ᚦ", "ᛝ"])
    end

    it "returns separately parsed words" do
      text = "fu th"

      result = Primus.parse(text).map { |word| word.tokens.map(&:index) }

      expect(result).to eq([[0, 1], [2]])
    end
  end
end
