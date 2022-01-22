class Primus::Document::Mask
  def initialize(mask:)
    @mask = mask.split("").map(&:to_i).to_enum
  end

  def visit_word(word)
    filter = Proc.new { |tk| next_bit == 0 }
    tokens = word.reject(&filter)
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end

  protected

  attr_reader :mask

  def next_bit
    mask.next
  rescue StopIteration
    mask.rewind
    mask.next
  end
end
