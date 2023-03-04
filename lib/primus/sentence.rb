class Primus::Sentence
  include Comparable
  include Enumerable

  attr_reader :text

  def initialize(text: [])
    @text = text
  end

  def ==(sentence)
    text.zip(sentence.text).all? { |a, b| a == b }
  end

  def <<(element)
    @text << element
  end

  def each(&block)
    text.each(&block)
  end

  def words
    text.select { |w| w.is_a? Primus::Word }
  end

  def accept(visitor)
    visitor.visit_sentence(self)
  end
end
