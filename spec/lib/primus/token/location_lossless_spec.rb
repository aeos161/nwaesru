RSpec.describe Primus::Token::Location do
  describe "#==" do
    context "with nil" do
      it "does not equate a real compatibility position with no location" do
        location = Primus::Token::Location.new(line: 0, position: 6)

        result = location == nil

        expect(result).to be_falsy
      end
    end

    context "with an incompatible object" do
      it "returns false without reading missing coordinate methods" do
        location = Primus::Token::Location.new(line: 0, position: 6)

        result = location == Object.new

        expect(result).to be_falsy
      end
    end
  end
end
