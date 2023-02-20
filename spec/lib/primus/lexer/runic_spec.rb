RSpec.describe Primus::Lexer::Runic do
  describe "#extract_lexeme" do
    it "handles a single character" do
      lexer = Primus::Lexer::Runic.new(data: "ᚫ")

      result = lexer.extract_lexeme

      expect(result).to eq("ᚫ")
    end

    it "handles a bi gram" do
      lexer = Primus::Lexer::Runic.new(data: "᛬᛫")

      result = lexer.extract_lexeme

      expect(result).to eq("᛬᛫")
    end
  end

  describe "#create_token" do
    it "tokenizes a character" do
      lexer = Primus::Lexer::Runic.new
      lexer.current_lexeme = "ᚫ"

      result = lexer.create_token

      expect(result).to eq(Primus::Token::Character.new(lexeme: "ᚫ"))
    end

    it "tokenizes a number" do
      lexer = Primus::Lexer::Runic.new
      lexer.current_lexeme = "7"

      result = lexer.create_token

      expect(result).to eq(Primus::Token::Character.new(lexeme: "7"))
    end

    it "tokenizes a word delimeter" do
      lexer = Primus::Lexer::Runic.new
      lexer.current_lexeme = "-"

      result = lexer.create_token

      expect(result).to eq(Primus::Token::WordDelimiter.new(lexeme: "-"))
    end

    it "tokenizes a bigram punctuation mark" do
      lexer = Primus::Lexer::Runic.new
      lexer.current_lexeme = "᛬᛫"

      result = lexer.create_token

      expect(result).to eq(Primus::Token::Punctuation.new(lexeme: "᛬᛫"))
    end

    it "tokenizes the end of a sentence" do
      lexer = Primus::Lexer::Runic.new
      lexer.current_lexeme = "᛭"

      result = lexer.create_token

      expect(result).to eq(Primus::Token::SentenceDelimiter.new(lexeme: "᛭"))
    end

    it "tokenizes an apostrophe" do
      lexer = Primus::Lexer::Runic.new
      lexer.current_lexeme = "'"

      result = lexer.create_token

      expect(result).to eq(Primus::Token::Punctuation.new(lexeme: "'"))
    end

    it "tokenizes a quotation mark" do
      lexer = Primus::Lexer::Runic.new
      lexer.current_lexeme = '"'

      result = lexer.create_token

      expect(result).to eq(Primus::Token::QuotationMark.new(lexeme: "\""))
    end

    it "tokenizes a line break" do
      lexer = Primus::Lexer::Runic.new
      lexer.current_lexeme = "/"

      result = lexer.create_token

      expect(result).to eq(Primus::Token::LineBreak.new(lexeme: "/"))
    end

    context "when the lexeme is not recognized" do
      it "raises an unknown token error" do
        lexer = Primus::Lexer::Runic.new
        lexer.current_lexeme = "?"

        expect {
          lexer.create_token
        }.to raise_error("Unknown Token: ?")
      end
    end
  end
end
