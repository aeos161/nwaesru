RSpec.describe Primus::Document::PatternMatcher do
  describe "#visit_word" do
    it "starts tracking on the first word length match" do
      first_word = create_word(%w(l i c e))
      matcher = Primus::Document::PatternMatcher.new(pattern: [4])

      matcher.visit_word(first_word)

      expect(matcher).to be_matching
    end

    it "starts a new match when it ends a previous match" do
      first_word = create_word(%w(m a n y))
      second_word = create_word(%w(l i c e))
      matcher = Primus::Document::PatternMatcher.new(pattern: [4, 2],
                                                     matching: true)

      matcher.visit_word(first_word)
      matcher.visit_word(second_word)

      expect(matcher.current_match).to match_array([second_word])
    end

    it "stops matching the first time it hits an unexpected word length" do
      second_word = create_word(%w(a n y))
      matcher = Primus::Document::PatternMatcher.new(pattern: [4, 2],
                                                     matching: true,
                                                     current_index: 1)

      matcher.visit_word(second_word)

      expect(matcher).not_to be_matching
    end

    it "stores the result when it finds a match" do
      first_word = create_word(%w(l i c e))
      second_word = create_word(%w(th e))
      third_word = create_word(%w(i n s t a r))
      matcher = Primus::Document::PatternMatcher.new(pattern: [4, 2, 6])

      matcher.visit_word(first_word)
      matcher.visit_word(second_word)
      matcher.visit_word(third_word)

      expect(matcher.results).to match_array([
        [first_word, second_word, third_word]
      ])
    end
  end

  describe "#visit_token" do
    it "returns the token" do
      visitor = Primus::Document::WordReverser.new
      token = Primus::Token::WordDelimiter.new

      result = visitor.visit_token(token)

      expect(result).to eq(token)
    end
  end
end
