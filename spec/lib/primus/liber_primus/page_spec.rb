RSpec.describe Primus::LiberPrimus::Page do
  describe ".open" do
    it "loads the page data" do
      result = Primus::LiberPrimus::Page.open(page_number: 56)
      path = Primus::LiberPrimus::Page.file_name(page_number: 56)
      data = Psych.safe_load(File.read(path))
      delimiter = Primus::LiberPrimus::Page::LINE_DELIMITER

      expect(result.lines).to eq(data["body"].split(delimiter))
    end
  end

  describe ".file_name" do
    it "builds the encoded file name" do
      result = Primus::LiberPrimus::Page.file_name(page_number: 56)

      expect(result).to eq("data/encoded/liber_primus/page56.yml")
    end

    context "encoded is false" do
      it "builds the decoded file name" do
        result = Primus::LiberPrimus::Page.file_name(page_number: 56,
                                                     encoded: false)

        expect(result).to eq("data/decoded/liber_primus/page56.yml")
      end
    end
  end

  describe "#to_s" do
    it "joins the lines into a string" do
      file = Primus::LiberPrimus::Page.new(lines: ["ab bg cd", "dc ef   \n"])
      expected_text = <<~TEXT
        ab bg cd
        dc ef
      TEXT

      result = file.to_s

      expect(result).to eq(expected_text.rstrip)
    end
  end
end
