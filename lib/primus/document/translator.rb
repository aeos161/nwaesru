class Primus::Document::Translator
  attr_reader :dictionary

  def initialize(dictionary: nil, search_key: :rune)
    @dictionary = dictionary || Primus::GematriaPrimus.instance
    @search_key = search_key || :rune
  end

  def skip_sequence=(value); end

  def visit_word(word)
    tokens = word.map do |tk|
      token = dictionary.find_by(search_key => tk.lexeme)
      token.location = tk.location
      token
    end
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end

  protected

  attr_reader :search_key
end
