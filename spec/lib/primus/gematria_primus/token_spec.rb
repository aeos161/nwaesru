RSpec.describe Primus::GematriaPrimus::Token do
  describe "#+" do
    it "sums the values" do
      alphabet = Primus::GematriaPrimus.build
      r = alphabet.find_by(value: 11)
      f = alphabet.find_by(value: 2)

      result = r + f

      expect(result).to eq(13)
    end
  end

  describe "#-" do
    it "subtracts the values" do
      alphabet = Primus::GematriaPrimus.build
      c = alphabet.find_by(value: 13)
      f = alphabet.find_by(value: 2)

      result = c - f

      expect(result).to eq(11)
    end
  end

  describe "#<<" do
    it "shifts the token up by the index" do
      alphabet = Primus::GematriaPrimus.build
      j = alphabet.find_by(index: 11)
      th = alphabet.find_by(index: 2)
      p = alphabet.find_by(index: 13)

      result = j << th

      expect(result).to eq(p)
    end
  end

  describe "#>>" do
    it "shifts the token down by the index" do
      alphabet = Primus::GematriaPrimus.build
      j = alphabet.find_by(index: 11)
      th = alphabet.find_by(index: 2)
      p = alphabet.find_by(index: 13)

      result = p >> th

      expect(result).to eq(j)
    end
  end

  describe "#^" do
    it "xors the indexes" do
      alphabet = Primus::GematriaPrimus.build
      r = alphabet.find_by(index: 4)
      c = alphabet.find_by(index: 5)
      u = alphabet.find_by(index: 1)

      result = r ^ c

      expect(result).to eq(u)
    end
  end

  describe "#factors" do
    it "factors the letter as a sum of the input and other letters" do
      alphabet = Primus::GematriaPrimus.build
      c = alphabet.find_by(letter: "c")
      r = alphabet.find_by(letter: "r")
      f = alphabet.find_by(letter: "f")

      result = c.factors(r)

      expect(result.first).to contain_exactly(r, f)
    end

    it "only returns factors including the input" do
      alphabet = Primus::GematriaPrimus.build
      e = alphabet.find_by(letter: "e")
      s = alphabet.find_by(letter: "s")

      result = e.factors(s)

      result.each do |combo|
        expect(combo).to include(s)
      end
    end
  end
end
