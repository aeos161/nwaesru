RSpec.describe Primus::Document::TotientShift do
  describe "#visit_word" do
    it "shifts the letter by the totient number" do
      dictionary = Primus::GematriaPrimus.build
      visitor = Primus::Document::TotientShift.new
      tokens = [
        dictionary.find_by(rune: "ᚫ"),
        dictionary.find_by(rune: "ᛄ"),
        dictionary.find_by(rune: "ᛟ"),
      ]
      word = Primus::Word.new(tokens: tokens)

      result = visitor.visit_word(word)

      expect(result.to_s(:letter)).to eq("ane")
    end

    context "for a character not in gematria prime" do
      it "does not shift the letter" do
        visitor = Primus::Document::TotientShift.new
        tokens = [Primus::GematriaPrimus::Token.new(rune: "a", letter: "a")]
        word = Primus::Word.new(tokens: tokens)

        result = visitor.visit_word(word)

        expect(result.to_s(:letter)).to eq("a")
      end
    end

    context "for an interrupter" do
      it "does not shift the letter" do
        alphabet = Primus::GematriaPrimus.build
        visitor = Primus::Document::TotientShift.new(
          alphabet: alphabet, number_of_characters_processed: 56,
          interrupter_sequence: [56]
        )
        tokens = [alphabet.find_by(rune: "ᚠ")]
        word = Primus::Word.new(tokens: tokens)

        result = visitor.visit_word(word)

        expect(result.to_s(:letter)).to eq("f")
      end
    end
  end

  describe "#visit_token" do
    it "returns the token" do
      visitor = Primus::Document::TotientShift.new
      token = Primus::Token::WordDelimiter.new

      result = visitor.visit_token(token)

      expect(result).to eq(token)
    end
  end
end
