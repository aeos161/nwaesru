class Primus::Document::Filter
  attr_reader :filtered

  def initialize(character_to_reject:)
    @character_to_reject = character_to_reject
    @filtered = []
  end

  def visit_word(word)
    filter = Proc.new { |tk| tk.lexeme == character_to_reject }
    @filtered += word.select(&filter).flatten.compact
    tokens = word.reject(&filter)
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end

  protected

  attr_reader :character_to_reject
end
