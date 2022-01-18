RSpec.describe Primus::Document::Atbash do
  describe "#visit_word" do
    it "translates the token to their gematria primus equivalent" do
      alphabet = Primus::GematriaPrimus.build
      visitor = Primus::Document::Atbash.new(alphabet: alphabet)
      word = Primus::Word.new(tokens: [alphabet.find_by(rune: "ᛈ")])

      result = visitor.visit_word(word)

      expect(result).to eq(Primus::Word.new(tokens: [
        alphabet.find_by(rune: "ᛋ"),
      ]))
    end
  end

  describe "#visit_token" do
    it "returns the token" do
      visitor = Primus::Document::Atbash.new
      token = Primus::Token::WordDelimiter.new

      result = visitor.visit_token(token)

      expect(result).to eq(token)
    end
  end
end
