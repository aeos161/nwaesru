RSpec.describe Primus::Document do
  describe "#word_count" do
    it "returns the number of words" do
      document = Primus::Document.new(text: [
        Primus::Word.new, Primus::Word.new, Primus::Token::WordDelimiter.new
      ])

      result = document.word_count

      expect(result).to eq(2)
    end
  end
end
