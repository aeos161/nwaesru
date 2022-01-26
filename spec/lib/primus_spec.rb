RSpec.describe Primus do
  describe "#index_of_coincidence" do
    it "calculates the index of coincidence" do
      alphabet = Primus::LatinAlphabet.build
      text = create_word(%w(w e l c o m e))
      numerator = [0, 2, 0, 0, 0, 0].sum
      denominator = (7 * 6) / 26.to_f
      index_of_coincidence = numerator / denominator

      result = Primus.index_of_coincidence(text: text, alphabet: alphabet)

      expect(result).to eq(index_of_coincidence)
    end
  end
end
