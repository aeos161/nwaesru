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
  end

  describe "#visit_token" do
    it "returns the token" do
      visitor = Primus::Document::TokenCounter.new
      token = Primus::Token::WordDelimiter.new

      result = visitor.visit_token(token)

      expect(result).to eq(token)
    end
  end
end
