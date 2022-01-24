class Primus::GematriaPrimus
  include Enumerable

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
    word.map(&:value).sum(0)
  end

  def generate_words(sum:, number_of_characters:)
    tokens.
      repeated_permutation(number_of_characters).
      select { |arr| arr.map(&:value).sum == sum }.
      map { |tks| Primus::Word.new(tokens: tks) }.
      map { |word| word.to_s(:letter) }
  end

  def self.build
    path = "data/gematria_primus.yml"
    alphabet = Psych.safe_load(File.read(path))["tokens"]
    tokens = alphabet.map.with_index do |data, index|
      params = data.transform_keys(&:to_sym).merge(index: index)
      Token.new(params)
    end
    new(tokens: tokens)
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
