RSpec.describe Primus::Token do
  describe "#==" do
    context "all the attributes are equal" do
      it "is equal" do
        tokenA = Primus::Token.new(lexeme: "ᚠ", literal: "ᚠ")
        tokenB = Primus::Token.new(lexeme: "ᚠ", literal: "ᚠ")

        expect(tokenA).to eq(tokenB)
      end
    end

    context "the attributes are not equal" do
      it "is not equal" do
        tokenA = Primus::Token.new(lexeme: "ᚠ", literal: "ᚠ")
        tokenB = Primus::Token.new(lexeme: "ᚢ", literal: "ᚢ")

        expect(tokenA).not_to eq(tokenB)
      end
    end
  end
end
