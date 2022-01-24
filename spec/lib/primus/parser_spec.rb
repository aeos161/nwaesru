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

    it "removes line breaks within a word" do
      tokens = [
        Primus::Token::Character.new(lexeme: "ᚫ", location: double),
        Primus::Token::Character.new(lexeme: "ᛄ", location: double),
        Primus::Token::LineBreak::new(location: double),
        Primus::Token::Character.new(lexeme: "ᛟ", location: double),
        Primus::Token::Character.new(lexeme: "ᚱ", location: double),
        Primus::Token::WordDelimiter::new(location: double),
      ]
      parser = Primus::Parser.new(tokens: tokens)

      parser.parse
      result = parser.result

      expect(result.text.first).to eq(
        Primus::Word.new(tokens: [
          Primus::Token::Character.new(lexeme: "ᚫ", location: double),
          Primus::Token::Character.new(lexeme: "ᛄ", location: double),
          Primus::Token::Character.new(lexeme: "ᛟ", location: double),
          Primus::Token::Character.new(lexeme: "ᚱ", location: double),
        ])
      )
    end

    it "maintains line breaks outside a word" do
      tokens = [
        Primus::Token::Character.new(lexeme: "a", location: double),
        Primus::Token::Character.new(lexeme: "b", location: double),
        Primus::Token::Character.new(lexeme: "1", location: double),
        Primus::Token::Character.new(lexeme: "2", location: double),
        Primus::Token::LineBreak::new(location: double),
      ]
      parser = Primus::Parser.new(tokens: tokens)

      parser.parse
      result = parser.result

      expect(result.text).to eq([
        Primus::Word.new(tokens: [
          Primus::Token::Character.new(lexeme: "a", location: double),
          Primus::Token::Character.new(lexeme: "b", location: double),
          Primus::Token::Character.new(lexeme: "1", location: double),
          Primus::Token::Character.new(lexeme: "2", location: double),
        ]),
        Primus::Token::LineBreak::new(location: double),
      ])
    end

    context "the text does not end with a word boundary" do
      it "builds the word" do
        tokens = [
          Primus::Token::Character.new(lexeme: "ᚫ", location: double),
          Primus::Token::Character.new(lexeme: "ᛄ", location: double),
        ]
        parser = Primus::Parser.new(tokens: tokens)

        parser.parse

        expect(parser.result.first).to eq(
          Primus::Word.new(tokens: [
            Primus::Token::Character.new(lexeme: "ᚫ", location: double),
            Primus::Token::Character.new(lexeme: "ᛄ", location: double),
          ])
        )
      end
    end
  end
end
