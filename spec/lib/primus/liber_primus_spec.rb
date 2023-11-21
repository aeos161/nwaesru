RSpec.describe Primus::LiberPrimus do
  describe ".page" do
    it "builds the page from runic characters" do
      actual_text = File.open("spec/fixtures/files/page56.txt").read
      actual_text = actual_text.lstrip.rstrip

      result = Primus::LiberPrimus.page(page_number: 56, strategy: :runic)

      expect(result.to_s(:rune)).to eq(actual_text)
    end

    it "builds the page from latin characters" do
      actual_text = File.open("spec/fixtures/files/page56_latin.txt").read
      actual_text = actual_text.lstrip.rstrip

      result = Primus::LiberPrimus.page(page_number: 56, strategy: :latin)

      expect(result.to_s(:latin)).to eq(actual_text)
    end
  end

  describe ".chapter" do
    it "correctly builds the expected pages" do
      chapter = Primus::LiberPrimus.chapter(page_numbers: 8..14,
                                            strategy: :runic)
      actual_text = File.open("spec/fixtures/files/chapter12.txt").read
      actual_text = actual_text.lstrip.rstrip

      result = chapter.to_s(:rune)

      expect(result).to eq(actual_text)
    end
  end
end
