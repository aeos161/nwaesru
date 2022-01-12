RSpec.describe Primus::GematriaPrimus do
  describe ".builder" do
    it "sets the 29 translations" do
      result = Primus::GematriaPrimus.build

      expect(result.translations.size).to eq(29)
    end
  end

  describe ".dictionary" do
    it "contains all 29 runes" do
      result = Primus::GematriaPrimus.dictionary

      expect(result.size).to eq(29)
    end
  end

  describe "#find_translation" do
    it "returns the translation for the rune" do
      tr1 = build_translation(index: 0, rune: "ᚠ", letter: "f", value: 2)
      tr2 = build_translation(index: 1, rune: "ᚢ", letter: "u", value: 3)
      translator = Primus::GematriaPrimus.new(translations: [tr1, tr2])

      result = translator.find_translation(rune: "ᚢ")

      expect(result).to eq(tr2)
    end
  end

  def build_translation(rune:, index:, letter:, value:)
    Primus::GematriaPrimus::Translation.new(index: index, rune: rune,
                                            letter: letter, value: value)
  end
end
