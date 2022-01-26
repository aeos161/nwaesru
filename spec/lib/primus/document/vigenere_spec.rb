RSpec.describe Primus::Document::Vigenere do
  describe "#visit_word" do
    it "decodes the word" do
      key = "diuinity"
      plain_text = create_word(%w(w e l c o m e))
      cipher_text = create_word(%w(u ea ng s eo f c))
      visitor = Primus::Document::Vigenere.new(key: key)

      result = visitor.visit_word(cipher_text)

      expect(result).to eq(plain_text)
    end
  end

  describe "#visit_token" do
    it "returns the token" do
      anything = ""
      visitor = Primus::Document::Vigenere.new(key: anything)
      token = Primus::Token::WordDelimiter.new

      result = visitor.visit_token(token)

      expect(result).to eq(token)
    end
  end
end
