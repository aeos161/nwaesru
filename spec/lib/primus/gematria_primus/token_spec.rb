RSpec.describe Primus::GematriaPrimus::Token do
  describe "#==" do
    context "all the attributes are equal" do
      it "is equal" do
        tokenA = Primus::GematriaPrimus::Token.new(index: 0, rune: "ᚠ",
                                                   letter: "f", value: 2)
        tokenB = Primus::GematriaPrimus::Token.new(index: 0, rune: "ᚠ",
                                                   letter: "f", value: 2)

        expect(tokenA).to eq(tokenB)
      end
    end

    context "the attributes are not equal" do
      it "is not equal" do
        tokenA = Primus::GematriaPrimus::Token.new(index: 0, rune: "ᚠ",
                                                   letter: "f", value: 2)
        tokenB = Primus::GematriaPrimus::Token.new(index: 1, rune: "ᚢ",
                                                   letter: "u", value: 3)

        expect(tokenA).not_to eq(tokenB)
      end
    end

  end
end
