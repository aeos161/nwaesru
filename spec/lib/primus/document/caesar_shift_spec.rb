RSpec.describe Primus::Document::CaesarShift do
  describe "#visit_word" do
    it "decodes the word" do
      key = 1
      plain_text = create_word(%w(w e l c o m e))
      cipher_text = create_word(%w(h m ng g r l m))
      visitor = Primus::Document::CaesarShift.new(key: key)

      result = visitor.visit_word(cipher_text)

      expect(result).to eq(plain_text)
    end
  end

  def create_word(text)
    alphabet = Primus::GematriaPrimus.build
    tks = Array(text).map { |tk| alphabet.find_by(letter: tk) }
    Primus::Word.new(tokens: tks)
  end
end
