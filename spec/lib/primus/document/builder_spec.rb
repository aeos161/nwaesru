RSpec.describe Primus::Document::Builder do
  describe "#build_page" do
    it "it tokenizes the page" do
      lexer = Primus::Lexer.new
      allow(lexer).to receive(:tokenize)
      allow(Primus::Lexer).to receive(:build).and_return(lexer)
      builder = Primus::Document::Builder.new
      page = Primus::LiberPrimus::Page.new

      builder.build_page(page)

      expect(lexer).to have_received(:tokenize).once
    end

    it "parses the tokens" do
      parser = Primus::Parser.new
      allow(parser).to receive(:parse)
      allow(Primus::Parser).to receive(:new).and_return(parser)
      builder = Primus::Document::Builder.new
      page = Primus::LiberPrimus::Page.new

      builder.build_page(page)

      expect(parser).to have_received(:parse).once
    end
  end

  describe ".for_pages" do
    it "sets the pages" do
      page8 = Primus::LiberPrimus::Page.open(page_number: 8)

      result = Primus::Document::Builder.for_pages(page_numbers: 8)

      expect(result.pages).to match_array([page8])
    end
  end
end
