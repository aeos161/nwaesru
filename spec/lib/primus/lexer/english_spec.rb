RSpec.describe Primus::Lexer::English do
  describe "#initialize" do
    it "standardizes the case of the data" do
      lexer = Primus::Lexer::English.new(data: "AB")

      expect(lexer.data).to match_array(["a", "b"])
    end
  end

  describe "#extract_lexeme" do
    it "handles a single character" do
      lexer = Primus::Lexer::English.new(data: "a")

      result = lexer.extract_lexeme

      expect(result).to eq("a")
    end

    it "handles a bi gram" do
      lexer = Primus::Lexer::English.new(data: "ae")

      result = lexer.extract_lexeme

      expect(result).to eq("ae")
    end

    it "handles a tri gram" do
      lexer = Primus::Lexer::English.new(data: "ing")

      result = lexer.extract_lexeme

      expect(result).to eq("ing")
    end
  end

  describe "#create_token" do
    it "tokenizes a character" do
      lexer = Primus::Lexer::English.new
      lexer.current_lexeme = "a"

      result = lexer.create_token

      expect(result).to eq(Primus::Token::Character.new(lexeme: "a"))
    end

    it "tokenizes a bigram character" do
      lexer = Primus::Lexer::English.new
      lexer.current_lexeme = "ae"

      result = lexer.create_token

      expect(result).to eq(Primus::Token::Character.new(lexeme: "ae"))
    end

    it "tokenizes a trigram character" do
      lexer = Primus::Lexer::English.new
      lexer.current_lexeme = "ing"

      result = lexer.create_token

      expect(result).to eq(Primus::Token::Character.new(lexeme: "ing"))
    end

    it "tokenizes a number" do
      lexer = Primus::Lexer::English.new
      lexer.current_lexeme = "7"

      result = lexer.create_token

      expect(result).to eq(Primus::Token::Character.new(lexeme: "7"))
    end

    it "tokenizes a word delimeter" do
      lexer = Primus::Lexer::English.new
      lexer.current_lexeme =  " "

      result = lexer.create_token

      expect(result).to eq(Primus::Token::WordDelimiter.new(lexeme: " "))
    end

    it "tokenizes the end of a sentence" do
      lexer = Primus::Lexer::English.new
      lexer.current_lexeme = "."

      result = lexer.create_token

      expect(result).to eq(Primus::Token::SentenceDelimiter.new(lexeme: "."))
    end

    it "tokenizes an apostrophe" do
      lexer = Primus::Lexer::English.new
      lexer.current_lexeme = "'"

      result = lexer.create_token

      expect(result).to eq(Primus::Token::Punctuation.new(lexeme: "'"))
    end

    it "tokenizes a quotation mark" do
      lexer = Primus::Lexer::English.new
      lexer.current_lexeme = '"'

      result = lexer.create_token

      expect(result).to eq(Primus::Token::QuotationMark.new(lexeme: "\""))
    end

    it "tokenizes a line break" do
      lexer = Primus::Lexer::English.new
      lexer.current_lexeme = "/"

      result = lexer.create_token

      expect(result).to eq(Primus::Token::LineBreak.new(lexeme: "/"))
    end

    context "when the lexeme is not recognized" do
      it "raises an unknown token error" do
        lexer = Primus::Lexer::English.new
        lexer.current_lexeme = "ᚫ"

        expect {
          lexer.create_token
        }.to raise_error("Unknown Token: ᚫ")
      end
    end
  end
end
