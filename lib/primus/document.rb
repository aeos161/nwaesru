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
    words.flat_map(&:tokens).detect { |tk| tk.location.position == index }
  end

  def each(&block)
    text.each(&block)
  end

  def to_s(format: :letter)
    visitor = Primus::Document::Printer.new(format: format)
    accept(visitor)
    visitor.to_s
  end

  def empty?
    text.empty?
  end

  def word_count
    words.size
  end

  def character_count
    words.map(&:size).sum
  end

  def words
    text.select { |w| w.is_a? Primus::Word }
  end

  def accept(visitor)
    visited_text = text.map { |element| element.accept(visitor) }
    Primus::Document.new(text: visited_text)
  end
end
