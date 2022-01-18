class Primus::GematriaPrimus::Calculator
  def visit_word(word)
    word.
      map(&:value).
      compact.
      sum
  end

  def visit_token(_token)
    nil
  end
end
