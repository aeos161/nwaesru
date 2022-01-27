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

  describe "#to_word" do
    it "standardizes the word" do
      text = "zkia"

      result = Primus.to_word(text: text)

      expect(result.to_s(:letter)).to eq("scio")
    end

    it "properly tokenizes the word" do
      text = "aethereal"

      result = Primus.to_word(text: text)

      expect(result.tokens).to match_array([
        Primus::Token::Character.new(lexeme: "ae"),
        Primus::Token::Character.new(lexeme: "th"),
        Primus::Token::Character.new(lexeme: "e"),
        Primus::Token::Character.new(lexeme: "r"),
        Primus::Token::Character.new(lexeme: "ea"),
        Primus::Token::Character.new(lexeme: "l"),
      ])
    end
  end
end
