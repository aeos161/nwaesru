RSpec.describe Primus::Translator do
  describe "#translate" do
    it "translates to english characters" do
      strategy = Primus::RuneToLetter.new(translator: double.as_null_object)
      allow(strategy).to receive(:translate)
      doc = Primus::LiberPrimus::Document.new(words: [
        Primus::LiberPrimus::Word.new,
        Primus::LiberPrimus::Word.new,
      ])
      translator = Primus::Translator.new(document: doc, strategy: strategy)

      translator.translate

      expect(strategy).to have_received(:translate).twice
    end

    it "sets a result" do
      strategy = Primus::RuneToLetter.new(translator: double.as_null_object)
      doc = Primus::LiberPrimus::Document.new(words: [
        Primus::LiberPrimus::Word.new
      ])
      translator = Primus::Translator.new(document: doc, strategy: strategy)

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

    it "parses the page" do
      strategy = double.as_null_object
      page = Primus::LiberPrimus::Page.new
      parser = Primus::LiberPrimus::Parser.new
      allow(parser).to receive(:parse)
      allow(Primus::LiberPrimus::Parser).to receive(:new).and_return(parser)

      Primus::Translator.build(page: page, strategy: strategy)

      expect(parser).to have_received(:parse).once
    end
  end
end
