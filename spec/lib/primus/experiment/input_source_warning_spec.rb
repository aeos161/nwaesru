RSpec.describe Primus::Experiment::InputSource do
  describe "#initialize" do
    it "resolves only the explicit Warning selector to the real YAML path" do
      selection = { "id" => "page-warning", "sha256" =>
        "86a0a2a4d68c2fff1af86d3e7aa62bec05eb46a2bdbc480d4243bcf282561718" }

      source = described_class.new(selection: selection, occurrence: 0)

      expect(source.path).to eq("data/encoded/liber_primus/page_warning.yml")
    end

    it "retains Warning as a string page identity" do
      selection = { "id" => "page-warning", "sha256" =>
        "86a0a2a4d68c2fff1af86d3e7aa62bec05eb46a2bdbc480d4243bcf282561718" }

      source = described_class.new(selection: selection, occurrence: 1)

      expect(source.manifest(0).values_at("page_number", "occurrence")).to eq(["warning", 1])
    end

    it "does not resolve page zero to Warning" do
      selection = { "id" => "page-0", "sha256" =>
        "86a0a2a4d68c2fff1af86d3e7aa62bec05eb46a2bdbc480d4243bcf282561718" }

      action = -> { described_class.new(selection: selection, occurrence: 0) }

      expect(action).to raise_error(ArgumentError)
    end
  end

  describe "#page" do
    it "passes the original Warning identity into source coordinates" do
      selection = { "id" => "page-warning", "sha256" =>
        "86a0a2a4d68c2fff1af86d3e7aa62bec05eb46a2bdbc480d4243bcf282561718" }
      source = described_class.new(selection: selection, occurrence: 0)

      page = source.page

      expect(page.number).to eq("warning")
    end
  end
end
