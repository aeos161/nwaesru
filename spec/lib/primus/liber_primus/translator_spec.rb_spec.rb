RSpec.describe Primus::LiberPrimus::Translator do
  describe "#translate" do
    it "translates to english characters" do
      page = Primus::LiberPrimus::Page.new(lines: ["", ""], number: 1)
      strategy = Primus::RuneToLetter.new(translator: double.as_null_object)
      allow(strategy).to receive(:translate)
      translator = Primus::LiberPrimus::Translator.new(page: page,
                                                       strategy: strategy)

      translator.translate

      expect(strategy).to have_received(:translate).twice
    end

    it "sets a result" do
      page = Primus::LiberPrimus::Page.new(lines: [""], number: 1)
      strategy = Primus::RuneToLetter.new(translator: double.as_null_object)
      translator = Primus::LiberPrimus::Translator.new(page: page,
                                                       strategy: strategy)

      translator.translate

      expect(translator.result).not_to be_empty
    end
  end
end
