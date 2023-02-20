RSpec.describe Primus::Lexer do
  describe ".build" do
    it "loads the data for a page" do
      page = Primus::LiberPrimus::Page.new(data: "lexical data")

      lexer = Primus::Lexer.build(page: page, strategy: :english)

      expect(lexer.data).to match_array(page.data.split("").to_enum)
    end
  end

  describe "#tokenize" do
    it "tokenizes an entire rune sentence" do
      lexer = Primus::Lexer.new(data: "ᚫᛄ-ᛟᛋᚱ.")

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::Character.new(lexeme: "ᚫ"),
        Primus::Token::Character.new(lexeme: "ᛄ"),
        Primus::Token::WordDelimiter::new,
        Primus::Token::Character.new(lexeme: "ᛟ"),
        Primus::Token::Character.new(lexeme: "ᛋ"),
        Primus::Token::Character.new(lexeme: "ᚱ"),
        Primus::Token::SentenceDelimiter.new,
      ])
    end

    it "tokenizes an entire letter sentence" do
      lexer = Primus::Lexer.new(data: "good luck.")

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::Character.new(lexeme: "g"),
        Primus::Token::Character.new(lexeme: "o"),
        Primus::Token::Character.new(lexeme: "o"),
        Primus::Token::Character.new(lexeme: "d"),
        Primus::Token::WordDelimiter::new,
        Primus::Token::Character.new(lexeme: "l"),
        Primus::Token::Character.new(lexeme: "u"),
        Primus::Token::Character.new(lexeme: "c"),
        Primus::Token::Character.new(lexeme: "c"),
        Primus::Token::SentenceDelimiter.new,
      ])
    end

    it "standardizes the case of the letters" do
      lexer = Primus::Lexer.new(data: "AB")

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::Character.new(lexeme: "a"),
        Primus::Token::Character.new(lexeme: "b"),
      ])
    end

    it "standarizes the bi graphs" do
      lexer = Primus::Lexer.new(data: "ing")

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::Character.new(lexeme: "ng"),
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

    it "handles punctuation" do
      lexer = Primus::Lexer.new(data: "King Arthur was at Caerlleon upon Usk;")

      lexer.tokenize
      last_token = lexer.tokens.last

      expect(last_token).to eq(Primus::Token::Punctuation.new(lexeme: ";"))
    end
  end
end
