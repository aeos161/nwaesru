RSpec.describe Primus::Document::TotientShift do
  describe "#visit_word" do
    it "keeps original coordinates after shifting a rune" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::LiberPrimus::Page.new(number: 55, data: "ᚠ")],
      )
      builder.build
      word = builder.result.accept(Primus::Document::Translator.new).words.first
      visitor = Primus::Document::TotientShift.new

      shifted = visitor.visit_word(word).tokens.first

      expect(shifted.source_location).to have_attributes(
        page_number: 55, rune_index: 0, byte_start: 0, byte_end: 3,
      )
    end
  end

  describe "#visit_sentence" do
    it "exempts page 56 rune index 56 without changing its letter" do
      document = Primus::LiberPrimus.page(page_number: 56)
      visitor = Primus::Document::TotientShift.new
      visitor.skip_sequence = [56]
      translated = document.accept(Primus::Document::Translator.new)

      decoded = translated.accept(visitor)
      letters = decoded.tokens.select { |token|
        token.respond_to?(:index) && !token.index.nil?
      }.map(&:letter)

      expect(letters[56]).to eq("f")
    end

    it "uses the next prime after the exempt page 56 rune" do
      document = Primus::LiberPrimus.page(page_number: 56)
      visitor = Primus::Document::TotientShift.new
      visitor.skip_sequence = [56]
      translated = document.accept(Primus::Document::Translator.new)

      decoded = translated.accept(visitor)
      letters = decoded.tokens.select { |token|
        token.respond_to?(:index) && !token.index.nil?
      }.map(&:letter)

      expect(letters[57]).to eq("e")
    end
  end
end
