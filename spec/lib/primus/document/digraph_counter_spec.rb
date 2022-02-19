RSpec.describe Primus::Document::DigraphCounter do
  describe "#visit_word" do
    it "counts the digraphs" do
      l = 20
      i = 10
      b = 17
      e = 18
      word = create_word(%w(l i b e r))
      counter = Primus::Document::DigraphCounter.new

      counter.visit_word(word)
      result = counter.result

      expect(result[l][i]).to eq(1)
      expect(result[b][e]).to eq(1)
    end

    it "includes any left over tokens" do
      alphabet = Primus::GematriaPrimus.build
      left_over = alphabet.find_by(letter: "r")
      word = create_word(%w(p r i m u s))
      r = 4
      p = 13
      i = 10
      counter = Primus::Document::DigraphCounter.new(left_over_token: left_over)

      counter.visit_word(word)
      result = counter.result

      expect(result[r][p]).to eq(1)
      expect(result[r][i]).to eq(1)
      expect(result[p][r]).to be_zero
    end
  end
end
