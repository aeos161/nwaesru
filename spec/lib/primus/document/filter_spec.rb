RSpec.describe Primus::Document::Filter do
  describe "#visit_word" do
    it "filters out the character to reject" do
      visitor = Primus::Document::Filter.new(character_to_reject: "ᛉ")
      token = Primus::Word.new(tokens: [
        Primus::Token::Character.new(lexeme: "ᛈ"),
        Primus::Token::Character.new(lexeme: "ᛉ"),
        Primus::Token::Character.new(lexeme: "ᛋ"),
      ])

      result = visitor.visit_word(token)

      expect(result).to eq(Primus::Word.new(tokens: [
        Primus::Token::Character.new(lexeme: "ᛈ"),
        Primus::Token::Character.new(lexeme: "ᛋ"),
      ]))
    end
  end

  describe "#visit_token" do
    it "returns the token" do
      visitor = Primus::Document::Filter.new(character_to_reject: "ᛉ")
      token = Primus::Token::WordDelimiter.new

      result = visitor.visit_token(token)

      expect(result).to eq(token)
    end
  end
end
