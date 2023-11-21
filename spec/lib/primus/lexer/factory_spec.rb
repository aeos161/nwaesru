RSpec.describe Primus::Lexer::Factory do
  describe "#build" do
    it "returns an instance of a lexer strategy" do
      factory = Primus::Lexer::Factory.new(strategy: :latin)

      result = factory.build

      expect(result).to be_an_instance_of(Primus::Lexer::Latin)
    end

    it "returns an instance of a lexer strategy" do
      factory = Primus::Lexer::Factory.new(strategy: :runic)

      result = factory.build

      expect(result).to be_an_instance_of(Primus::Lexer::Runic)
    end

    context "no lexer is found for the strategy" do
      it "raises an error" do
        factory = Primus::Lexer::Factory.new(strategy: :cyrillic)

        expect {
          factory.build
        }.to raise_error("No lexer for: cyrillic")
      end
    end
  end
end
