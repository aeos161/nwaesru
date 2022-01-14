class Primus::LiberPrimus::Document
  include Enumerable

  attr_reader :words

  def initialize(words: [])
    @words = words
    @word_delimiter ||= Primus::LiberPrimus::Page::WORD_DELIMITER
  end

  def ==(document)
    words == document.words
  end

  def each(&block)
    words.each(&block)
  end

  def to_s
    words.map { |word| word.to_s(:rune) }.join(word_delimiter).strip
  end

  def size
    words.size
  end

  protected

  attr_reader :word_delimiter
end
