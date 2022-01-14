RSpec.describe Primus::LiberPrimus::Parser do
  describe "#parse" do
    it "does not maintain the lines" do
      parser = Primus::LiberPrimus::Parser.new(lines: [
        "ᚫᛄ-ᛟᛋᚱ.ᛗᚣᛚᚩᚻ-ᚩᚫ-ᚳᚦᚷᚹ-ᚹᛚᚫ-ᛉ",
        "ᚩᚪᛈ-ᛗᛞᛞᚢᚷᚹ-ᛚ-ᛞᚾᚣᛄ-ᚳᚠᛡ-ᚫᛏ",
      ])

      parser.parse
      result = parser.result

      expect(result.size).not_to eq(2)
    end

    it "maintains words" do
      dictionary = Primus::GematriaPrimus.build
      parser = Primus::LiberPrimus::Parser.new(lines: ["ᚫ-ᛟ.ᛗ"])

      parser.parse
      result = parser.result

      expect(result).to match_array([
        Primus::LiberPrimus::Word.new(tokens: [dictionary.find_by(rune: "ᚫ")]),
        Primus::LiberPrimus::Word.new(tokens: [dictionary.find_by(rune: "ᛟ")]),
        Primus::LiberPrimus::Word.new(tokens: [dictionary.find_by(rune: "ᛗ")]),
      ])
    end
  end
end
