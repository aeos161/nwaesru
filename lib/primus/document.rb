class Primus::Document
  include Enumerable

  attr_reader :text

  def initialize(text: [])
    @text = text || []
  end

  def ==(document)
    text == document.text
  end

  def <<(text)
    @text << text
  end

  def [](index)
    tokens.detect do |tk|
      tk.location&.position == index
    end
  end

  def each(&block)
    text.each(&block)
  end

  def to_s(format = :letter)
    visitor = Primus::Document::Printer.new(format: format)
    accept(visitor)
    visitor.to_s
  end

  def sentence_count
    sentences.size
  end

  def word_count
    words.size
  end

  def character_count
    counter = Primus::Document::TokenCounter.new
    accept(counter)
    counter.size
  end

  def index_of_coincidence(length: 1)
    Primus.index_of_coincidence(document: self, length: length)
  end

  def sentences
    @sentences ||= text.select { |w| w.is_a? Primus::Sentence }
  end

  def words
    @words ||= sentences.flat_map(&:words)
  end

  def tokens
    words.flat_map(&:tokens)
  end

  def reverse
    reverser = Primus::Document::WordReverser.new
    reversed_words = accept(reverser)
    Primus::Document.new(text: reversed_words.text.reverse)
  end

  def scan(pattern)
    matcher = Primus::Document::PatternMatcher.new(pattern: pattern)
    accept(matcher)
    matcher.results
  end

  def accept(visitor)
    visited_text = text.map { |element| element.accept(visitor) }
    Primus::Document.new(text: visited_text)
  end
end
