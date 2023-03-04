class Primus::Document::Translator
  attr_reader :dictionary

  def initialize(dictionary: nil, strategy: :runic)
    @dictionary = dictionary || Primus::GematriaPrimus.instance
    @strategy = strategy || :runic
  end

  def skip_sequence=(value); end

  def visit_sentence(sentence)
    text = sentence.map { |w| w.accept(self) }
    Primus::Sentence.new(text: text)
  end

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

  attr_reader :strategy

  def search_key
    return :rune if strategy == :runic
    :letter
  end
end
