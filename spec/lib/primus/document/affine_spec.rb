RSpec.describe Primus::Document::Affine do
  describe "#visit_word" do
    it "decodes the word" do
      key = 26
      magnitude = 9
      plain_text = create_word(%w(w e l c o m e))
      cipher_text = create_word(%w(b p w d f i p))
      visitor = Primus::Document::Affine.new(key: key, magnitude: magnitude)

      result = visitor.visit_word(cipher_text)

      expect(result).to eq(plain_text)
    end

    context "key and magnitude are not co-prime" do
      it "raises an error" do
        key = 0
        magnitude = 0
        cipher_text = create_word(%w(b p w d f i p))
        visitor = Primus::Document::Affine.new(key: key, magnitude: magnitude)

        expect {
          visitor.visit_word(cipher_text)
        }.to raise_error("0 and 0 are not co-prime")
      end
    end
  end

  describe "#visit_token" do
    it "returns the token" do
      visitor = Primus::Document::Affine.new(key: 1, magnitude: 1)
      token = Primus::Token::WordDelimiter.new

      result = visitor.visit_token(token)

      expect(result).to eq(token)
    end
  end
end
