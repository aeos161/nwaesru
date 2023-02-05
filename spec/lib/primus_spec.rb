RSpec.describe Primus do
  describe "#index_of_coincidence" do
    it "calculates the index of coincidence" do
      alphabet = Primus::LatinAlphabet.build
      text = create_word(%w(w e l c o m e))
      numerator = [0, 2, 0, 0, 0, 0].sum
      denominator = (7 * 6) / 26.to_f
      index_of_coincidence = numerator / denominator
      document = Primus::Document.new(text: [text])

      result = Primus.index_of_coincidence(document: document,
                                           alphabet: alphabet)

      expect(result).to eq(index_of_coincidence)
    end
  end

  describe "#to_word" do
    it "standardizes the word" do
      text = "zkio"

      result = Primus.to_word(text)

      expect(result.to_s(:letter)).to eq("scia")
    end

    it "properly tokenizes the word" do
      alphabet = Primus::GematriaPrimus.build
      text = "aethereal"

      result = Primus.to_word(text)

      expect(result.tokens).to match_array([
        alphabet.find_by(letter: "ae"),
        alphabet.find_by(letter: "th"),
        alphabet.find_by(letter: "e"),
        alphabet.find_by(letter: "r"),
        alphabet.find_by(letter: "ea"),
        alphabet.find_by(letter: "l"),
      ])
    end
  end
end
