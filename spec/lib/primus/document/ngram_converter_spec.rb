RSpec.describe Primus::Document::NgramConverter do
  describe "#convert" do
    it "groups the document into two character sections" do
      alphabet = Primus::GematriaPrimus.build
      word1 = Primus::Word.new(tokens: [alphabet.find_by(rune: "ᚪ")])
      word2 = Primus::Word.new(tokens: [
        alphabet.find_by(rune: "ᚳ"), alphabet.find_by(rune: "ᚪ"),
        alphabet.find_by(rune: "ᛏ")
      ])
      document = Primus::Document.new(text: [
        word1, Primus::Token::WordDelimiter.new, word2
      ])
      converter = Primus::Document::NgramConverter.new(
        document: document, length: 2
      )

      converter.convert
      result = converter.result

      expect(result.to_s(:rune)).to eq("ᚪ.ᚳ-ᚪ.ᛏ")
    end
  end
end
