RSpec.describe Primus::Parser do
  describe "#parse" do
    it "groups tokens into words" do
      tokens = [
        Primus::Token::Character.new(lexeme: "ᚫ", location: double),
        Primus::Token::Character.new(lexeme: "ᛄ", location: double),
        Primus::Token::WordDelimiter::new(location: double),
        Primus::Token::Character.new(lexeme: "ᛟ", location: double),
        Primus::Token::Character.new(lexeme: "ᚱ", location: double),
        Primus::Token::SentenceDelimiter.new(location: double),
      ]
      parser = Primus::Parser.new(tokens: tokens)

      parser.parse
      result = parser.result

      expect(result.word_count).to eq(2)
    end
  end
end
