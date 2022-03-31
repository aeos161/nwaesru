RSpec.describe Primus::Page do
  xdescribe "#==" do
    context "the data is the same" do
      it "is equal" do

      end
    end

    context "the data is different" do
      it "is not equal" do

      end
    end
  end

  xdescribe "#to_s" do
    it "converts the data into a string" do
    end
  end

  describe ".open" do
    it "opens the page" do
      path = [Primus::Page::DECODED_DIR_PATH, "2012/mabinogion.yml"].join("/")
      data = Psych.safe_load(File.read(path))

      result = Primus::Page.open(path: "2012/mabinogion")

      expect(result.data).to eq(data["body"])
    end
  end

  describe ".load_data" do
    it "loads the page data" do
      path = [Primus::Page::DECODED_DIR_PATH, "2012/mabinogion.yml"].join("/")
      data = Psych.safe_load(File.read(path))

      result = Primus::Page.load_data(path)

      expect(result).to eq(data["body"])
    end
  end
end
