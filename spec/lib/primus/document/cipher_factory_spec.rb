RSpec.describe Primus::Document::CipherFactory do
  describe "#find" do
    it "returns a cipher decode" do
      factory = Primus::Document::CipherFactory.new(name: :runes)

      result = factory.find

      expect(result).to respond_to(:visit_word)
    end

    it "sets the key" do
      factory = Primus::Document::CipherFactory.new(name: :vigenere)
      factory.key = "test"

      result = factory.find

      expect(result.key.map { |k| k.to_s(:letter) }.join).to eq("test")
    end

    it "sets the key" do
      factory = Primus::Document::CipherFactory.new(name: :totient)
      factory.skip_sequence = [1, 2, 3]

      result = factory.find

      expect(result.skip_sequence).to match_array([1, 2, 3])
    end
  end
end
