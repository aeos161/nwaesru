RSpec.describe Primus::Document::Translator do
  describe "#visit_word" do
    it "translates the token to their gematria primus equivalent" do
      dictionary = Primus::GematriaPrimus.build
      visitor = Primus::Document::Translator.new(dictionary: dictionary)
      word = Primus::Word.new(tokens: [
        Primus::Token::Character.new(lexeme: "ᛈ"),
        Primus::Token::Character.new(lexeme: "ᛋ"),
      ])

      result = visitor.visit_word(word)

      expect(result).to eq(Primus::Word.new(tokens: [
        dictionary.find_by(rune: "ᛈ"),
        dictionary.find_by(rune: "ᛋ"),
      ]))
    end

    it "translates alternate english characters" do
      dictionary = Primus::GematriaPrimus.build
      visitor = Primus::Document::Translator.new(dictionary: dictionary,
                                                 strategy: :english)
      word = Primus::Word.new(tokens: [
        Primus::Token::Character.new(lexeme: "z"),
        Primus::Token::Character.new(lexeme: "ing"),
      ])

      result = visitor.visit_word(word)

      expect(result).to eq(Primus::Word.new(tokens: [
        dictionary.find_by(letter: "s"),
        dictionary.find_by(letter: "ng"),
      ]))
    end

    it "does not translate new line characters" do
      dictionary = Primus::GematriaPrimus.build
      visitor = Primus::Document::Translator.new(dictionary: dictionary)
      word = Primus::Word.new(tokens: [
        Primus::Token::Character.new(lexeme: "ᛈ"),
        Primus::Token::LineBreak.new(lexeme: "/"),
        Primus::Token::Character.new(lexeme: "ᛋ"),
      ])

      result = visitor.visit_word(word)

      expect(result).to eq(Primus::Word.new(tokens: [
        dictionary.find_by(rune: "ᛈ"),
        Primus::Token::LineBreak.new(lexeme: "/"),
        dictionary.find_by(rune: "ᛋ"),
      ]))

    end
  end

  describe "#visit_token" do
    context "the token is a character" do
      it "translates the character to the dictionary" do
        dictionary = Primus::GematriaPrimus.instance
        visitor = Primus::Document::Translator.new(dictionary: dictionary)
        token = Primus::Token::Character.new(lexeme: "ᛈ")

        result = visitor.visit_token(token)

        expect(result).to eq(dictionary.find_by(rune: "ᛈ"))
      end
    end

    context "the token is a line break" do
      it "returns the token" do
        visitor = Primus::Document::Translator.new
        token = Primus::Token::LineBreak.new

        result = visitor.visit_token(token)

        expect(result).to eq(token)
      end
    end

    context "the token is a delimiter" do
      it "returns the token" do
        visitor = Primus::Document::Translator.new
        token = Primus::Token::WordDelimiter.new

        result = visitor.visit_token(token)

        expect(result).to eq(token)
      end
    end
  end
end
