RSpec.describe Primus::Document::Mask do
  describe "#visit_word" do
    it "filters out the character with a 0 bit" do
      visitor = Primus::Document::Mask.new(mask: "1001")
      word = Primus::Word.new(tokens: [
        Primus::Token::Character.new(lexeme: "ᛈ"),
        Primus::Token::Character.new(lexeme: "ᚠ"),
        Primus::Token::Character.new(lexeme: "ᛋ"),
        Primus::Token::Character.new(lexeme: "ᛉ"),
      ])

      result = visitor.visit_word(word)

      expect(result).to eq(Primus::Word.new(tokens: [
        Primus::Token::Character.new(lexeme: "ᛈ"),
        Primus::Token::Character.new(lexeme: "ᛉ"),
      ]))
    end

    it "stores the filtered out characters" do
      pending
      fail
    end
  end

  describe "#visit_token" do
    it "returns the token" do
      visitor = Primus::Document::Mask.new(mask: "1001")
      token = Primus::Token::WordDelimiter.new

      result = visitor.visit_token(token)

      expect(result).to eq(token)
    end
  end
end
