RSpec.describe Primus::Translator do
  describe "#translate" do
    it "translates to english characters" do
      strategy = Primus::RuneToLetter.new(translator: double.as_null_object)
      allow(strategy).to receive(:translate)
      translator = Primus::Translator.new(data: "ᛈᚪ-ᛈᚪᚪ.", strategy: strategy)

      translator.translate

      expect(strategy).to have_received(:translate).twice
    end

    it "sets a result" do
      strategy = Primus::RuneToLetter.new(translator: double.as_null_object)
      translator = Primus::Translator.new(data: "ᛈᚪ-", strategy: strategy)

      translator.translate

      expect(translator.result).not_to be_empty
    end
  end

  describe ".build" do
    it "sets the strategy" do
      page = double.as_null_object
      strategy = Primus::RuneToLetter.new(translator: double.as_null_object)

      result = Primus::Translator.build(page: page, strategy: strategy)

      expect(result.strategy).to eq(strategy)
    end
  end
end
