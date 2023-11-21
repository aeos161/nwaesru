RSpec.describe Primus::LiberPrimus::Page do
  describe ".open" do
    context "an encoded page" do
      it "loads the page data and removes white space" do
        path = Primus::LiberPrimus::Page.file_name(page_number: 56,
                                                   character_set: :runic)
        data = Psych.safe_load(File.read(path))

        result = Primus::LiberPrimus::Page.open(page_number: 56,
                                                character_set: :runic)

        expect(result.data).to eq(data["body"].rstrip)
      end
    end

    context "a decoded page" do
      it "loads the page data" do
        result = Primus::LiberPrimus::Page.open(page_number: 56,
                                                character_set: :latin)
        path = Primus::LiberPrimus::Page.file_name(page_number: 56,
                                                   character_set: :latin)
        data = Psych.safe_load(File.read(path))

        expect(result.data).to eq(data["body"].rstrip)
      end
    end
  end

  describe ".file_name" do
    it "builds the encoded file name" do
      result = Primus::LiberPrimus::Page.file_name(page_number: 56)

      expect(result).to eq("data/encoded/liber_primus/page_56.yml")
    end

    context "encoded is false" do
      it "builds the decoded file name" do
        result = Primus::LiberPrimus::Page.file_name(page_number: 56,
                                                     character_set: :latin)

        expect(result).to eq("data/decoded/liber_primus/page_56.yml")
      end
    end
  end
end
