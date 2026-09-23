RSpec.describe Primus::Document::Vigenere do
  describe "#visit_word" do
    it "retains the original source reference on a decoded rune" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::LiberPrimus::Page.new(number: 55, data: "ᚠ")],
      )
      builder.build
      word = builder.result.accept(Primus::Document::Translator.new).words.first
      visitor = Primus::Document::Vigenere.new(key: "a")

      decoded = visitor.visit_word(word).tokens.first

      expect(decoded.source_location).to have_attributes(
        page_number: 55, rune_index: 0, byte_start: 0, byte_end: 3,
      )
    end
  end
end
