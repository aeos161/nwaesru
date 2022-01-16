RSpec.describe Primus::RuneToLetter do
  describe "#translate" do
    it "convers a line of runs into letters" do
      gematria_primus = Primus::GematriaPrimus.build
      algorithm = Primus::RuneToLetter.new(translator: gematria_primus)
      runes = [build_token(rune: "ᚳ"), build_token(rune: "ᚫ")]
      word = Primus::Word.new(tokens: runes)

      result = algorithm.translate(word: word)

      expect(result.to_s(:letter)).to eq("cae")
    end
  end

  describe ".build" do
    it "sets the gematrius prime as the translator" do
      gematria = Primus::GematriaPrimus.build
      allow(Primus::GematriaPrimus).to receive(:build).and_return(gematria)
      result = Primus::RuneToLetter.build

      expect(result.translator).to eq(gematria)
    end
  end

  def build_token(rune:)
    Primus::Token.new(lexeme: rune)
  end
end
