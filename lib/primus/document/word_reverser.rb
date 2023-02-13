class Primus::Document::WordReverser
  def visit_word(word)
    word.reverse
  end

  def visit_token(token)
    token
  end
end
