class Primus::Document::Printer
  attr_reader :format

  def initialize(format: :rune, maintain_line_breaks: true)
    @data = []
    @format = format || :rune
    @maintain_line_breaks = maintain_line_breaks
  end

  def to_s
    @data.join.rstrip
  end

  def visit_sentence(sentence)
    sentence.text.each { |tx| tx.accept(self) }
  end

  def visit_word(word)
    word.tokens.each { |tx| tx.accept(self) }
  end

  def visit_token(token)
    return if token.line_break? && !maintain_line_breaks?
    @data << token.to_s(format)
  end

  protected

  def maintain_line_breaks?
    true if @maintain_line_breaks
  end
end
