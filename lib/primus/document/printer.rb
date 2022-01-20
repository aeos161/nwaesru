class Primus::Document::Printer
  attr_reader :format

  def initialize(format: :rune)
    @data = []
    @format = format || :rune
  end

  def to_s
    @data.join.rstrip
  end

  def visit_word(word)
    @data << word.to_s(format)
  end

  def visit_token(token)
    @data << token.to_s(format)
  end
end
