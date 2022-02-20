class Primus::Document::TokenCounter
  attr_reader :result

  def initialize(alphabet: nil, length: 1, left_over_token: nil)
    @alphabet ||= Primus::GematriaPrimus.build
    @length = length || 1
    @left_over_token = left_over_token
    initialize_result
  end

  def to_s
    alphabet.map(&:letter).zip(@result)
  end

  def size
    if length == 1
      result.sum
    else
      result.map(&:sum).sum
    end
  end

  def visit_word(word)
    tokens = word.tokens.dup
    apply_left_over_token tokens
    capture_new_left_over_token tokens
    count tokens
    word
  end

  def visit_token(token)
    token
  end

  private

  attr_reader :alphabet, :length

  def apply_left_over_token(tokens)
    return if @left_over_token.nil?
    tokens.unshift @left_over_token
    @left_over_token = nil
  end

  def capture_new_left_over_token(tokens)
    return if (tokens.size % length) == 0
    @left_over_token = tokens.pop
  end

  def count(tokens)
    tokens.to_enum.each_slice(length) do |tks|
      if tks.size == 2
        @result[tks[0].index][tks[1].index] += 1
      else
        @result[tks[0].index] += 1
      end
    end
  end

  def initialize_result
    row = [].fill(0, 0, alphabet.size)
    @result = []
    if length == 1
      @result = row
    else
      0.upto(@alphabet.size - 1).reduce(@result) do |res, n|
        res[n] = row.dup
        res
      end
    end
  end
end
