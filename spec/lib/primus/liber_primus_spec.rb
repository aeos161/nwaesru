RSpec.describe Primus::LiberPrimus do
  describe ".page" do
    it "builds the page" do
      document = build_document(page_numbers: 56)

      result = Primus::LiberPrimus.page(page_number: 56)

      expect(result).to eq(document)
    end
  end

  describe ".chapter" do
    it "builds the chapter" do
      document = build_document(page_numbers: 8..14)

      result = Primus::LiberPrimus.chapter(page_numbers: 8..14)

      expect(result).to eq(document)
    end
  end

  def build_document(page_numbers:)
    builder = Primus::Document::Builder.for_pages(page_numbers: page_numbers)
    builder.build
    builder.result
  end
end
