RSpec.describe Primus::TotientShift do
  describe "#translate" do
    it "shifts the letter by the totient number" do
      translator = Primus::GematriaPrimus.build
      algorithm = Primus::TotientShift.new(translator: translator)
      chars = [build_token(rune: "ᚫ"), build_token(rune: "ᛄ"),
               build_token(rune: "ᛟ")]
      word = Primus::Word.new(tokens: chars)

      result = algorithm.translate(word: word)

      expect(result.to_s(:letter)).to eq("ane")
    end
  end

  describe ".build" do
    it "sets the gematrius prime as the translator" do
      gematria = Primus::GematriaPrimus.build
      allow(Primus::GematriaPrimus).to receive(:build).and_return(gematria)
      result = Primus::TotientShift.build

      expect(result.translator).to eq(gematria)
    end
  end

  def build_token(rune:)
    Primus::Token::Character.new(lexeme: rune)
  end
end
