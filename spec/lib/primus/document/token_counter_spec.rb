RSpec.describe Primus::Document::TokenCounter do
  describe "#visit_word" do
    it "counts each token" do
      alphabet = Primus::GematriaPrimus.build
      token = alphabet.find_by(index: 0)
      word = Primus::Word.new(tokens: [token, token])
      counter = Primus::Document::TokenCounter.new

      counter.visit_word(word)

      expect(counter.result[0]).to eq(2)
    end

    context "for digraphs" do
      it "counts groups of tokens" do
        l = 20
        i = 10
        b = 17
        e = 18
        word = create_word(%w(l i b e r))
        counter = Primus::Document::TokenCounter.new(length: 2)

        counter.visit_word(word)
        result = counter.result

        expect(result[l][i]).to eq(1)
        expect(result[b][e]).to eq(1)
      end

      it "includes any left over tokens" do
        alphabet = Primus::GematriaPrimus.build
        left_over = alphabet.find_by(letter: "r")
        word = create_word(%w(p r i m u s))
        r = 4
        p = 13
        i = 10
        counter = Primus::Document::TokenCounter.new(length: 2,
                                                     left_over_token: left_over)

        counter.visit_word(word)
        result = counter.result

        expect(result[r][p]).to eq(1)
        expect(result[r][i]).to eq(1)
        expect(result[p][r]).to be_zero
      end
    end
  end

  describe "#visit_token" do
    it "returns the token" do
      visitor = Primus::Document::TokenCounter.new
      token = Primus::Token::WordDelimiter.new

      result = visitor.visit_token(token)

      expect(result).to eq(token)
    end
  end

  describe "#size" do
    it "returns the number of tokens counted" do
      alphabet = Primus::GematriaPrimus.build
      token = alphabet.find_by(index: 0)
      word = Primus::Word.new(tokens: [token, token])
      counter = Primus::Document::TokenCounter.new

      counter.visit_word(word)

      expect(counter.size).to eq(2)
    end

    context "for digraphs" do
      it "returns the number of digraphs counted" do
        alphabet = Primus::GematriaPrimus.build
        token = alphabet.find_by(index: 0)
        word = Primus::Word.new(tokens: [token, token])
        counter = Primus::Document::TokenCounter.new(length: 2)

        counter.visit_word(word)

        expect(counter.size).to eq(1)
      end
    end
  end
end
