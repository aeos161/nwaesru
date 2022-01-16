RSpec.describe Primus::Lexer do
  describe ".build" do
    it "loads the data for a page" do
      page = Primus::LiberPrimus::Page.new(data: "lexical data")

      lexer = Primus::Lexer.build(page: page)

      expect(lexer.data).to match_array(page.data.split("").to_enum)
    end
  end

  describe "#tokenize" do
    it "tokenizes an entire sentence" do
      lexer = Primus::Lexer.new(data: "ᚫᛄ-ᛟᛋᚱ.")

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::Character.new(lexeme: "ᚫ", location: double),
        Primus::Token::Character.new(lexeme: "ᛄ", location: double),
        Primus::Token::WordDelimiter::new(location: double),
        Primus::Token::Character.new(lexeme: "ᛟ", location: double),
        Primus::Token::Character.new(lexeme: "ᛋ", location: double),
        Primus::Token::Character.new(lexeme: "ᚱ", location: double),
        Primus::Token::SentenceDelimiter.new(location: double),
      ])
    end

    it "tracks the line and position of each token" do
      lexer = Primus::Lexer.new(data: "ᚫᛄ-ᛟᛋᚱ./ᚫᛄ-ᛟᛋᚱ")

      lexer.tokenize
      last_token = lexer.tokens.last

      expect(last_token.location).to eq(
        Primus::Token::Location.new(line: 1, position: 9)
      )
    end

    context "a line and position are passed in" do
      it "starts tracking from that line and position" do
        lexer = Primus::Lexer.new(data: "ᚫᛄ-ᛟᛋᚱ", line: 2, position: 100)

        lexer.tokenize
        last_token = lexer.tokens.last

        expect(last_token.location).to eq(
          Primus::Token::Location.new(line: 2, position: 104)
        )
      end
    end
  end
end
