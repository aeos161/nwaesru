RSpec.describe Primus::Token::Location do
  describe "#==" do
    context "when line, position, and length are the same" do
      it "is equal" do
        locationA = Primus::Token::Location.new(line: 0, position: 6, length: 1)
        locationB = Primus::Token::Location.new(line: 0, position: 6, length: 1)

        expect(locationA).to eq(locationB)
      end
    end

    context "when line, position, or length are not the same" do
      it "is not equal" do
        locationA = Primus::Token::Location.new(line: 0, position: 6, length: 1)
        locationB = Primus::Token::Location.new(line: 1, position: 6, length: 2)

        expect(locationA).not_to eq(locationB)
      end
    end
  end

  describe "#-" do
    it "calculates the distance between two locatons" do
      locationA = Primus::Token::Location.new(line: 4, position: 62)
      locationB = Primus::Token::Location.new(line: 7, position: 127)

      result = locationB - locationA

      expect(result).to eq(65)
    end
  end
end
