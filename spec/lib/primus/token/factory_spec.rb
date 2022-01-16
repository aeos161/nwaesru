RSpec.describe Primus::Token::Factory do
  describe "#create_token" do
    context "for a rune" do
      it "instantiates a character" do
        factory = Primus::Token::Factory.new(lexeme: "ᚫ")

        result = factory.create_token

        expect(result).to eq(Primus::Token::Character.new(lexeme: "ᚫ"))
      end
    end

    context "for a character" do
      it "instantiates a character" do
        factory = Primus::Token::Factory.new(lexeme: "1")

        result = factory.create_token

        expect(result).to eq(Primus::Token::Character.new(lexeme: "1"))
      end
    end

    context "for a word delimiter" do
      it "instantiates a word delimiter" do
        factory = Primus::Token::Factory.new(
          lexeme: Primus::Token::WordDelimiter::IDENTIFIER
        )

        result = factory.create_token

        expect(result).to eq(Primus::Token::WordDelimiter.new)
      end
    end

    context "for a sentence delimiter" do
      it "instantiates a sentence delimiter" do
        factory = Primus::Token::Factory.new(
          lexeme: Primus::Token::SentenceDelimiter::IDENTIFIER
        )

        result = factory.create_token

        expect(result).to eq(Primus::Token::SentenceDelimiter.new)
      end
    end

    context "for a line break" do
      it "instantiates a line break" do
        factory = Primus::Token::Factory.new(
          lexeme: Primus::Token::LineBreak::IDENTIFIER
        )

        result = factory.create_token

        expect(result).to eq(Primus::Token::LineBreak.new)
      end
    end

    context "for an unknown lexeme" do
      it "raises an error" do
        factory = Primus::Token::Factory.new(lexeme: "!")

        expect {
          factory.create_token
        }.to raise_error("Unknown lexeme: !")
      end
    end
  end
end
