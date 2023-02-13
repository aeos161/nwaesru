RSpec.describe Primus::Document::WordReverser do
  describe "#visit_word" do
    it "reverses the word" do
      visitor = Primus::Document::WordReverser.new
      word = create_word(%w(th e))
      allow(word).to receive(:reverse).and_call_original

      visitor.visit_word(word)

      expect(word).to have_received(:reverse).once
    end
  end

  describe "#visit_token" do
    it "returns the token" do
      visitor = Primus::Document::WordReverser.new
      token = Primus::Token::WordDelimiter.new

      result = visitor.visit_token(token)

      expect(result).to eq(token)
    end
  end
end
