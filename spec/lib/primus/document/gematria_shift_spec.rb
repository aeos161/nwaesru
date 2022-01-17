RSpec.describe Primus::Document::GematriaShift do
  describe "#visit_word" do
    it "translates the token to their gematria primus equivalent" do
      dictionary = Primus::GematriaPrimus.build
      visitor = Primus::Document::GematriaShift.new(dictionary: dictionary)
      word = Primus::Word.new(tokens: [
        dictionary.find_by(rune: "ᛈ"),
      ])

      result = visitor.visit_word(word)

      expect(result).to eq(Primus::Word.new(tokens: [
        dictionary.find_by(rune: "ᛋ"),
      ]))
    end
  end

  describe "#visit_token" do
    it "returns the token" do
      visitor = Primus::Document::GematriaShift.new
      token = Primus::Token::WordDelimiter.new

      result = visitor.visit_token(token)

      expect(result).to eq(token)
    end
  end
end
