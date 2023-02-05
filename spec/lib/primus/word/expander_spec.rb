RSpec.describe Primus::Word::Expander do
  describe "#visit_word" do
    it "generates a word from the tokens" do
      word = create_word(%w(th e))
      expander = Primus::Word::Expander.new

      expander.visit_word(word)

      expect(expander.results).to match_array(["the"])
    end

    context "when then tokens have alternatives" do
      it "generates an array of all permuations" do
        word = create_word(%w(c n o w))
        expander = Primus::Word::Expander.new

        expander.visit_word(word)

        expect(expander.results).to match_array(["cnow", "know"])
      end

      it "generates an array of all permuations" do
        word = create_word(%w(s a c r e d))
        expander = Primus::Word::Expander.new

        expander.visit_word(word)

        expect(expander.results).to match_array([
          "sacred", "zacred", "sakred", "zakred"
        ])
      end
    end
  end
end
