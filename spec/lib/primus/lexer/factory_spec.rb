RSpec.describe Primus::Lexer::Factory do
  describe "#build" do
    it "returns an instance of a lexer strategy" do
      factory = Primus::Lexer::Factory.new(strategy: :english)

      result = factory.build

      expect(result).to be_an_instance_of(Primus::Lexer::English)
    end

    context "no lexer is found for the strategy" do
      it "raises an error" do
        factory = Primus::Lexer::Factory.new(strategy: :latin)

        expect {
          factory.build
        }.to raise_error("no lexer for latin")
      end
    end
  end
end
