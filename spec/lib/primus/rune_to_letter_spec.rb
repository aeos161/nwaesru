RSpec.describe Primus::RuneToLetter do
  describe "#translate" do
    it "convers a line of runs into letters" do
      gematria_primus = Primus::GematriaPrimus.build
      algorithm = Primus::RuneToLetter.new(translator: gematria_primus)
      runes = "ᚳᚫ"

      result = algorithm.translate(line: runes)

      expect(result.map(&:letter).join).to eq("cae")
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
end
