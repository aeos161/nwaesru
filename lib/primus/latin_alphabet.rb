class Primus::LatinAlphabet
  def initialize(tokens:)
    @tokens = tokens
  end

  def unique_tokens
    @unique_tokebns ||= tokens.map(&:letter).join.split("").uniq.sort
  end

  def expected_index_of_coincidence
    relative_frequencies = Primus.relative_word_frequencies_in_english
    c = unique_tokens.size.to_f
    (relative_frequencies.map { |freq| freq[1] ** 2 }.sum) / (1/c)
  end

  def self.build
    tokens = alphabet.map.with_index do |data, index|
      Token.new(data.merge(index: index))
    end
    new(tokens: tokens)
  end

  def self.alphabet
    [
      { letter: "a" },
      { letter: "b" },
      { letter: "c" },
      { letter: "d" },
      { letter: "e" },
      { letter: "f" },
      { letter: "g" },
      { letter: "h" },
      { letter: "i" },
      { letter: "j" },
      { letter: "k" },
      { letter: "l" },
      { letter: "m" },
      { letter: "n" },
      { letter: "o" },
      { letter: "p" },
      { letter: "q" },
      { letter: "r" },
      { letter: "s" },
      { letter: "t" },
      { letter: "u" },
      { letter: "v" },
      { letter: "w" },
      { letter: "x" },
      { letter: "y" },
      { letter: "z" },
    ]
  end

  protected

  attr_reader :tokens
end
