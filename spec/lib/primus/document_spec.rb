RSpec.describe Primus::Document do
  describe "#reverse" do
    it "reverses the document" do
      document = Primus::Document.new(text: [
        create_word(%w(l i c e)),
        Primus::Token::WordDelimiter.new,
        create_word(%w(th e)),
        Primus::Token::WordDelimiter.new,
        create_word(%w(i n s t a r))
      ])

      result = document.reverse

      expect(result.to_s).to eq("ratsni eth ecil")
    end
  end

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
