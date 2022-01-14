RSpec.describe Primus::TotientShift do
  describe "#translate" do
    it "shifts the letter by the totient number" do
      translator = Primus::GematriaPrimus.build
      algorithm = Primus::TotientShift.new(translator: translator)
      chars = [build_token(rune: "ᚫ", letter: "ae", value: 101, index: 25),
               build_token(rune: "ᛂ", letter: "j", value: 37, index: 11),
               build_token(rune: "ᛟ", letter: "oe", value: 83, index: 22)]
      word = Primus::LiberPrimus::Word.new(tokens: chars)

      result = algorithm.translate(word: word)

      expect(result.map(&:letter).join).to eq("ane")
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

  def build_token(rune:, letter:, value:, index:)
    Primus::GematriaPrimus::Token.
      new(rune: rune, letter: letter, value: value, index: index)
  end
end
