RSpec.describe Primus::LiberPrimus::Document do
  describe "#==" do
    context "the words are the same" do
      it "is equal" do
        dictionary = Primus::GematriaPrimus.build
        word =
          Primus::LiberPrimus::Word.new(tokens: [dictionary.find_by(rune: "ᚫ")])
        documentA = Primus::LiberPrimus::Document.new(words: [word])
        documentB = Primus::LiberPrimus::Document.new(words: [word])

        expect(documentA).to eq(documentB)
      end
    end

    context "the words are not the same" do
      it "is not equal" do
        dictionary = Primus::GematriaPrimus.build
        documentA = Primus::LiberPrimus::Document.new(words: [
          Primus::LiberPrimus::Word.new(tokens: [dictionary.find_by(rune: "ᚫ")])
        ])
        documentB = Primus::LiberPrimus::Document.new(words: [
          Primus::LiberPrimus::Word.new(tokens: [dictionary.find_by(rune: "ᛟ")])
        ])

        expect(documentA).not_to eq(documentB)
      end
    end
  end

  describe "#size" do
    it "returns the number of words" do
      dictionary = Primus::GematriaPrimus.build
      document = Primus::LiberPrimus::Document.new(words: [
        Primus::LiberPrimus::Word.new(tokens: [dictionary.find_by(rune: "ᚫ")]),
        Primus::LiberPrimus::Word.new(tokens: [dictionary.find_by(rune: "ᛟ")]),
      ])

      result = document.size

      expect(result).to eq(2)
    end
  end
end
