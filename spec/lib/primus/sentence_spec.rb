RSpec.describe Primus::Sentence do
  describe "#==" do
    context "all the words/tokens are equal" do
      it "is equal" do
        sentenceA = Primus::Sentence.new(text: [
          Primus::Word.new(tokens: [
            Primus::Token::Character.new(lexeme: "ᛟ", location: double),
            Primus::Token::Character.new(lexeme: "ᚱ", location: double),
          ]),
          Primus::Token::SentenceDelimiter::new(lexeme: "᛭", location: double)
        ])
        sentenceB = Primus::Sentence.new(text: [
          Primus::Word.new(tokens: [
            Primus::Token::Character.new(lexeme: "ᛟ", location: double),
            Primus::Token::Character.new(lexeme: "ᚱ", location: double),
          ]),
          Primus::Token::SentenceDelimiter::new(lexeme: "᛭", location: double)
        ])

        expect(sentenceA).to eq(sentenceB)
      end
    end

    context "the words/tokens are not equal" do
      it "is not equal" do
        sentenceA = Primus::Sentence.new(text: [
          Primus::Word.new(tokens: [
            Primus::Token::Character.new(lexeme: "ᛟ", location: double),
          ]),
          Primus::Token::SentenceDelimiter::new(lexeme: "᛭", location: double)
        ])
        sentenceB = Primus::Sentence.new(text: [
          Primus::Word.new(tokens: [
            Primus::Token::Character.new(lexeme: "ᛟ", location: double),
            Primus::Token::Character.new(lexeme: "ᚱ", location: double),
          ]),
          Primus::Token::SentenceDelimiter::new(lexeme: "᛭", location: double)
        ])

        expect(sentenceA).not_to eq(sentenceB)
      end
    end
  end

  describe "#<<" do
    it "adds a word to the sentence" do
      word = Primus::Word.new
      sentence = Primus::Sentence.new

      sentence << word

      expect(sentence.words).to match_array([word])
    end
  end

  describe "#squish" do
    it "removes new lines in words" do
      sentence = Primus::Sentence.new(text: [
        Primus::Word.new(tokens: [
          Primus::GematriaPrimus::Token.new(rune: "ᛟ", value: 83),
          Primus::Token::LineBreak.new,
          Primus::GematriaPrimus::Token.new(rune: "ᚱ", value: 11),
        ])
      ])

      result = sentence.squish

      expect(result.text).to match_array([
        Primus::Word.new(tokens: [
          Primus::GematriaPrimus::Token.new(rune: "ᛟ", value: 83),
          Primus::GematriaPrimus::Token.new(rune: "ᚱ", value: 11),
        ])
      ])
    end
  end

  describe "#sum" do
    it "sums all the words" do
      sentence = Primus::Sentence.new(text: [
        Primus::Word.new(tokens: [
          Primus::GematriaPrimus::Token.new(rune: "ᛟ", value: 83),
          Primus::GematriaPrimus::Token.new(rune: "ᚱ", value: 11),
        ]),
        Primus::Token::SentenceDelimiter::new(lexeme: "᛭", location: double),
        Primus::Word.new(tokens: [
          Primus::GematriaPrimus::Token.new(rune: "ᛇ", value: 41),
        ])
      ])

      result = sentence.sum

      expect(result).to match_array([94, 41])
    end
  end
end
