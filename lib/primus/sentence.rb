# TODO: gp sum for sentence
# TODO: easy prime matrix for sentence

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

  def to_s
    printer = Primus::Document::Printer.new(maintain_line_breaks: false)
    accept(printer)
    printer.to_s
  end

  def each(&block)
    text.each(&block)
  end

  def blank?
    text.empty?
  end

  def squish
    squished_text = text.map do |token|
      if token.respond_to? :squish
        token.squish
      else
        token
      end
    end
    Primus::Sentence.new(text: squished_text)
  end

  def sum
    words.map(&:sum)
  end

  def words
    text.select { |w| w.is_a? Primus::Word }
  end

  def accept(visitor)
    visitor.visit_sentence(self)
  end
end
