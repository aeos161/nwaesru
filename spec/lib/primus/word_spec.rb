RSpec.describe Primus::Word do
  describe "#==" do
    context "all the tokens are equal" do
      it "is equal" do
        wordA = Primus::Word.new(tokens: [
          Primus::Token::Character.new(lexeme: "ᚫ")
        ])
        wordB = Primus::Word.new(tokens: [
          Primus::Token::Character.new(lexeme: "ᚫ")
        ])

        expect(wordA).to eq(wordB)
      end
    end

    context "the tokens are not equal" do
      it "is not equal" do
        wordA = Primus::Word.new(tokens: [
          Primus::Token::Character.new(lexeme: "ᚫ")
        ])
        wordB = Primus::Word.new(tokens: [
          Primus::Token::Character.new(lexeme: "ᛟ")
        ])

        expect(wordA).not_to eq(wordB)
      end
    end
  end

  describe "#size" do
    it "returns the number of tokens" do
      word = Primus::Word.new(tokens: [
        Primus::Token.new,
        Primus::Token.new,
      ])

      result = word.size

      expect(result).to eq(2)
    end
  end

  describe "#sum" do
    it "sums the token values" do
      word = create_word(%w(d i u i n i t y))

      result = word.sum

      expect(result).to eq(376)
    end
  end
end
