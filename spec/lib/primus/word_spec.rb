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

  describe "#+" do
    it "adds words using modular arithmetic" do
      wordA = create_word(%w(c a r n a l))
      wordB = create_word(%w(a n a l o g))
      wordC = wordA - wordB

      result = wordC + wordB

      expect(result).to eq(wordA)
    end
  end

  describe "#-" do
    it "subtracts words using modular subtraction" do
      wordA = create_word(%w(c a r n a l))
      wordB = create_word(%w(a n a l o g))
      wordC = wordA + wordB

      result = wordC - wordA

      expect(result).to eq(wordB)
    end
  end

  describe "#^" do
    it "xors all the tokens of the word" do
      wordA = create_word(%w(c a r n a l))
      wordB = create_word(%w(a n a l o g))
      wordC = create_word(%w(f b ea f io e))

      result = wordA ^ wordB

      expect(result).to eq(wordC)
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
      word = create_word(%w(d i v i n i t y))

      result = word.sum

      expect(result).to eq(376)
    end
  end

  describe "#reverse" do
    it "reverses the word" do
      word = create_word(%w(i n s t a r))

      result = word.reverse

      expect(result).to eq(create_word(%w(r a t s n i)))
    end
  end

  describe "#squish" do
    it "removes new lines in the word" do
      word = Primus::Word.new(tokens: [
        Primus::GematriaPrimus::Token.new(rune: "ᛇ", value: 41),
        Primus::Token::LineBreak.new,
        Primus::GematriaPrimus::Token.new(rune: "ᛟ", value: 83),
        Primus::GematriaPrimus::Token.new(rune: "ᚱ", value: 11),
      ])

      new_word = word.squish

      expect(new_word.tokens).to match_array([
        Primus::GematriaPrimus::Token.new(rune: "ᛇ", value: 41),
        Primus::GematriaPrimus::Token.new(rune: "ᛟ", value: 83),
        Primus::GematriaPrimus::Token.new(rune: "ᚱ", value: 11),
      ])
    end
  end
end
