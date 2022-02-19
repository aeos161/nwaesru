class Primus::Document::DigraphCounter
  attr_reader :result

  def initialize(alphabet: nil, left_over_token: nil)
    @alphabet ||= Primus::GematriaPrimus.build
    row = [].fill(0, 0, @alphabet.size)
    @result = []
    0.upto(@alphabet.size).reduce(@result) do |res, n|
      res[n] = row.dup
      res
    end
    @left_over_token = left_over_token
  end

  def visit_word(word)
    tokens = word.tokens.dup
    apply_left_over_token tokens
    capture_new_left_over_token tokens
    count tokens
  end

  def visit_token(token)
    token
  end

  protected

  attr_reader :alphabet

  def apply_left_over_token(tokens)
    return if @left_over_token.nil?
    tokens.unshift @left_over_token
    @left_over_token = nil
  end

  def capture_new_left_over_token(tokens)
    return if tokens.size.even?
    @left_over_token = tokens.pop
  end

  def count(tokens)
    tokens.to_enum.each_slice(2) do |x, y|
      @result[x.index][y.index] += 1
    end
  end
end
