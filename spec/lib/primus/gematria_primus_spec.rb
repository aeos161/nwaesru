RSpec.describe Primus::GematriaPrimus do
  describe ".builder" do
    it "sets the 29 translations" do
      result = Primus::GematriaPrimus.build

      expect(result.size).to eq(29)
    end
  end

  describe ".dictionary" do
    it "contains all 29 runes" do
      result = Primus::GematriaPrimus.dictionary

      expect(result.size).to eq(29)
    end
  end

  describe "#find_by" do
    context "when a rune is supplied" do
      it "returns the token for the rune" do
        tk1 = build_token(index: 0, rune: "ᚠ", letter: "f", value: 2)
        tk2 = build_token(index: 1, rune: "ᚢ", letter: "u", value: 3)
        translator = Primus::GematriaPrimus.new(tokens: [tk1, tk2])

        result = translator.find_by(rune: "ᚢ")

        expect(result).to eq(tk2)
      end
    end

    context "when a letter is supplied" do
      it "returns the token for the letter" do
        tk1 = build_token(index: 0, rune: "ᚠ", letter: "f", value: 2)
        tk2 = build_token(index: 1, rune: "ᚢ", letter: "u", value: 3)
        translator = Primus::GematriaPrimus.new(tokens: [tk1, tk2])

        result = translator.find_by(letter: "f")

        expect(result).to eq(tk1)
      end
    end

    context "when an index is supplied" do
      it "returns the token for the index" do
        tk1 = build_token(index: 0, rune: "ᚠ", letter: "f", value: 2)
        tk2 = build_token(index: 1, rune: "ᚢ", letter: "u", value: 3)
        translator = Primus::GematriaPrimus.new(tokens: [tk1, tk2])

        result = translator.find_by(index: 1)

        expect(result).to eq(tk2)
      end
    end
  end

  def build_token(rune:, index:, letter:, value:)
    Primus::GematriaPrimus::Token.new(index: index, rune: rune, letter: letter,
                                      value: value)
  end
end
