RSpec.describe Primus::Document::Translator do
  describe "#visit_token" do
    it "carries an original source reference into the translated token" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::LiberPrimus::Page.new(number: 55, data: "ᚠ")],
      )
      builder.build
      translator = Primus::Document::Translator.new

      token = translator.visit_token(builder.result.tokens.first)

      expect(token.source_location).to have_attributes(
        page_number: 55, occurrence: 0, rune_index: 0,
        byte_start: 0, byte_end: 3, character_start: 0, character_end: 1
      )
    end

    it "does not assign the first page's reference to another translation" do
      first = Primus::Document::Builder.new(
        pages: [Primus::LiberPrimus::Page.new(number: 54, data: "ᚠ")],
      )
      second = Primus::Document::Builder.new(
        pages: [Primus::LiberPrimus::Page.new(number: 55, data: "ᚠ")],
      )
      first.build
      second.build
      translator = Primus::Document::Translator.new
      first_token = translator.visit_token(first.result.tokens.first)

      translator.visit_token(second.result.tokens.first)

      expect(first_token.source_location.page_number).to eq(54)
    end

    it "does not write source metadata into the shared GP alphabet" do
      builder = Primus::Document::Builder.new(
        pages: [Primus::LiberPrimus::Page.new(number: 55, data: "ᚠ")],
      )
      builder.build
      dictionary = Primus::GematriaPrimus.build
      translator = Primus::Document::Translator.new(dictionary: dictionary)
      alphabet_entry = dictionary.detect { |token| token.rune == "ᚠ" }

      translator.visit_token(builder.result.tokens.first)

      expect(alphabet_entry.source_location).to be_nil
    end
  end
end
