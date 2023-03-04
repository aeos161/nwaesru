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
end
