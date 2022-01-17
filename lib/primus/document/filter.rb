class Primus::Document::Filter
  def initialize(character_to_reject:)
    @character_to_reject = character_to_reject
  end

  def visit_word(word)
    tokens = word.reject { |tk| tk.lexeme == character_to_reject }
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end

  protected

  attr_reader :character_to_reject
end
