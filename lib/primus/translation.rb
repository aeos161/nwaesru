class Primus::Translation
  attr_reader :words

  def initialize(words:)
    @words = words
    @word_delimiter ||= " "
  end

  def to_s
    words.map { |word| word.to_s(:letter) }.join
  end

  def empty?
    words.empty?
  end

  protected

  attr_reader :word_delimiter
end
