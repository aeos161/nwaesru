RSpec.describe Primus::LiberPrimus::Page do
  describe ".open" do
    it "loads the page data" do
      result = Primus::LiberPrimus::Page.open(page_number: 56)
      path = Primus::LiberPrimus::Page.file_name(page_number: 56)
      data = Psych.safe_load(File.read(path))

      expect(result.lines).to eq(data["body"].split(" "))
    end
  end

  describe ".file_name" do
    it "builds the expected file name" do
      result = Primus::LiberPrimus::Page.file_name(page_number: 56)

      expect(result).to eq("data/liber_primus/page56.yml")
    end
  end
end
