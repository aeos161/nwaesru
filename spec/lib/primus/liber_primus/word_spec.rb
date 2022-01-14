RSpec.describe Primus::LiberPrimus::Word do
  describe "#==" do
    context "all the tokens are equal" do
      it "is equal" do
        dictionary = Primus::GematriaPrimus.build
        wordA = Primus::LiberPrimus::Word.new(tokens: [
          dictionary.find_by(rune: "ᚫ"),
        ])
        wordB = Primus::LiberPrimus::Word.new(tokens: [
          dictionary.find_by(rune: "ᚫ"),
        ])

        expect(wordA).to eq(wordB)
      end
    end

    context "the tokens are not equal" do
      it "is not equal" do
        dictionary = Primus::GematriaPrimus.build
        wordA = Primus::LiberPrimus::Word.new(tokens: [
          dictionary.find_by(rune: "ᚫ"),
        ])
        wordB = Primus::LiberPrimus::Word.new(tokens: [
          dictionary.find_by(rune: "ᛟ"),
        ])

        expect(wordA).not_to eq(wordB)
      end
    end
  end

  describe "#size" do
    it "returns the number of tokens" do
      word = Primus::LiberPrimus::Word.new(tokens: [
        Primus::GematriaPrimus::NoToken.new,
        Primus::GematriaPrimus::NoToken.new,
      ])

      result = word.size

      expect(result).to eq(2)
    end
  end
end
