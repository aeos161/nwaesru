class Primus::GematriaPrimus
  include Enumerable
  include Singleton

  def initialize(tokens:)
    @tokens = tokens
  end

  def each(&block)
    tokens.each(&block)
  end

  def size
    tokens.size
  end

  def find_by(rune: nil, letter: nil, index: nil, value: nil)
    finder = finder_factory(rune: rune, letter: letter, index: index,
                            value: value)
    result = tokens.detect(&finder)
    result.dup || Token.new(rune: rune, letter: rune)
  end

  def expected_index_of_coincidence
    frequencies = tokens.map { |tk| tk.frequency ** 2 }.sum
    frequencies / (1 / size.to_f)
  end

  def sum(word:)
    word.sum
  end

  def generate_words(number_of_characters:, sum: nil)
    by_sum = Proc.new do |tokens|
      if sum.nil?
        true
      else
        Array(sum).include? tokens.map(&:value).sum
      end
    end

    tokens.
      repeated_permutation(number_of_characters).
      select(&by_sum).
      map { |tks| Primus::Word.new(tokens: tks) }
  end

  def self.instance(tokens: nil)
    tokens ||= load_alphabet
    new(tokens: tokens)
  end

  def self.build(tokens: nil)
    instance(tokens: tokens)
  end

  def self.load_alphabet
    path = "data/gematria_primus.yml"
    alphabet = Psych.safe_load(File.read(path))["tokens"]
    alphabet.map.with_index do |data, index|
      params = data.transform_keys(&:to_sym).merge(index: index)
      Token.new(params)
    end
  end

  protected

  attr_reader :tokens

  def finder_factory(rune:, letter:, index:, value:)
    return build_finder(:rune, rune) unless rune.nil?
    return build_finder(:letter, letter) unless letter.nil?
    return build_finder(:index, index) unless index.nil?
    build_finder(:value, value)
  end

  def build_finder(method_name, value)
    Proc.new { |tk| tk.send(method_name) == value }
  end
end
