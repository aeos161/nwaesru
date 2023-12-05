RSpec.describe Primus::Lexer do
  describe ".build" do
    it "loads the data for a page" do
      page = Primus::LiberPrimus::Page.new(data: "lexical data")

      lexer = Primus::Lexer.build(page: page, strategy: :latin)

      expect(lexer.data).to match_array(page.data.split("").to_enum)
    end
  end

  describe "#tokenize" do
    it "tokenizes an entire runic sentence" do
      strategy = Primus::Lexer::Runic.new(data: "ᚫᛄ-ᛟᛋᚱ.")
      lexer = Primus::Lexer.new(strategy: strategy)

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::Character.new(lexeme: "ᚫ"),
        Primus::Token::Character.new(lexeme: "ᛄ"),
        Primus::Token::WordDelimiter::new(lexeme: "-"),
        Primus::Token::Character.new(lexeme: "ᛟ"),
        Primus::Token::Character.new(lexeme: "ᛋ"),
        Primus::Token::Character.new(lexeme: "ᚱ"),
        Primus::Token::SentenceDelimiter.new(lexeme: "."),
      ])
    end

    it "tokenizes an entire enlish sentence" do
      strategy = Primus::Lexer::Latin.new(data: "good luck.")
      lexer = Primus::Lexer.new(strategy: strategy)

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::Character.new(lexeme: "g"),
        Primus::Token::Character.new(lexeme: "o"),
        Primus::Token::Character.new(lexeme: "o"),
        Primus::Token::Character.new(lexeme: "d"),
        Primus::Token::WordDelimiter::new(lexeme: " "),
        Primus::Token::Character.new(lexeme: "l"),
        Primus::Token::Character.new(lexeme: "u"),
        Primus::Token::Character.new(lexeme: "c"),
        Primus::Token::Character.new(lexeme: "k"),
        Primus::Token::SentenceDelimiter.new(lexeme: "."),
      ])
    end

    it "tracks the line and position of each token" do
      strategy = Primus::Lexer::Runic.new(data: "ᚫᛄ-ᛟᛋᚱ.\nᚫᛄ-ᛟᛋᚱ",
                                          track_delimiters: false)
      lexer = Primus::Lexer.new(strategy: strategy)

      lexer.tokenize
      last_token = lexer.tokens.last

      expect(last_token.location).to eq(
        Primus::Token::Location.new(line: 1, position: 9)
      )
    end

    context "when told to track delimiters" do
      it "tracks the line and position of white space" do
        strategy = Primus::Lexer::Runic.new(data: "ᚫᛄ-ᛟᛋᚱ.\nᚫᛄ-ᛟᛋᚱ",
                                            track_delimiters: true)
        lexer = Primus::Lexer.new(strategy: strategy)

        lexer.tokenize
        white_space = lexer.tokens[10]

        expect(white_space.location).to eq(
          Primus::Token::Location.new(line: 1, position: 9)
        )
      end

      it "tracks the line and position of punctuation" do
        strategy = Primus::Lexer::Runic.new(data: "ᚫᛄ-ᛟᛋᚱ\nᚫᛄ-ᛟᛋᚱ.",
                                            track_delimiters: true)
        lexer = Primus::Lexer.new(strategy: strategy)

        lexer.tokenize
        punctuation = lexer.tokens[13]

        expect(punctuation.location).to eq(
          Primus::Token::Location.new(line: 1, position: 12)
        )
      end
    end

    context "a line and position are passed in" do
      it "starts tracking from that line and position" do
        strategy = Primus::Lexer::Runic.new(data: "ᚫᛄ-ᛟᛋᚱ", line: 2,
                                            position: 100)
        lexer = Primus::Lexer.new(strategy: strategy)

        lexer.tokenize
        last_token = lexer.tokens.last

        expect(last_token.location).to eq(
          Primus::Token::Location.new(line: 2, position: 104)
        )
      end
    end
  end
end
