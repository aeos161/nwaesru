RSpec.describe Primus::GematriaPrimus::Token do
  describe "#+" do
    it "sums the values and returns the new token" do
      alphabet = Primus::GematriaPrimus.build
      c = alphabet.find_by(value: 13)
      r = alphabet.find_by(value: 11)
      f = alphabet.find_by(value: 2)

      result = r + f

      expect(result).to eq(c)
    end
  end

  describe "#-" do
    it "subtracts the values and returns the new token" do
      alphabet = Primus::GematriaPrimus.build
      c = alphabet.find_by(value: 13)
      r = alphabet.find_by(value: 11)
      f = alphabet.find_by(value: 2)

      result = f - c

      expect(result).to eq(r)
    end
  end

  describe "#factors" do
    it "factors the letter as a sum of the input and other letters" do
      alphabet = Primus::GematriaPrimus.build
      c = alphabet.find_by(letter: "c")
      r = alphabet.find_by(letter: "r")
      f = alphabet.find_by(letter: "f")

      result = c.factors(r)
      binding.pry

      expect(result.first).to contain_exactly(r, f)
    end
  end
end
