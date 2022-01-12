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
end
