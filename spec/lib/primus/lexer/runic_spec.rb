RSpec.describe Primus::Lexer::Runic do
  describe "#tokenize" do
    it "tokenizes a character" do
      lexer = Primus::Lexer::Runic.new(data: "ᚫ")

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::Character.new(lexeme: "ᚫ")
      ])
    end

    it "tokenizes a number" do
      lexer = Primus::Lexer::Runic.new(data: "7")

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::Character.new(lexeme: "7")
      ])
    end

    it "tokenizes a word delimeter" do
      lexer = Primus::Lexer::Runic.new(data: "-")

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::WordDelimiter.new(lexeme: "-")
      ])
    end

    it "tokenizes a bigram punctuation mark" do
      lexer = Primus::Lexer::Runic.new(data: "᛬᛫")

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::Punctuation.new(lexeme: "᛬᛫")
      ])
    end

    it "tokenizes the end of a sentence" do
      lexer = Primus::Lexer::Runic.new(data: "᛭")

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::SentenceDelimiter.new(lexeme: "᛭")
      ])
    end

    it "tokenizes an apostrophe" do
      lexer = Primus::Lexer::Runic.new(data: "'")

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::Punctuation.new(lexeme: "'")
      ])
    end

    it "tokenizes a quotation mark" do
      lexer = Primus::Lexer::Runic.new(data: '"')

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::QuotationMark.new(lexeme: "\"")
      ])
    end

    it "tokenizes a line break" do
      lexer = Primus::Lexer::Runic.new(data: "/")

      lexer.tokenize

      expect(lexer.tokens).to match_array([
        Primus::Token::LineBreak.new(lexeme: "/")
      ])
    end

    context "when the lexeme is not recognized" do
      it "tokenizes a quotation mark" do
        lexer = Primus::Lexer::Runic.new(data: "?")

        expect {
          lexer.tokenize
        }.to raise_error("Unknown Token: ?")
      end
    end
  end
end
