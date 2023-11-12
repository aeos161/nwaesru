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
    tokens = word.map { |tk| visit_token(tk) }
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    return token if token.line_break? || token.delimiter?
    tk = dictionary.find_by(search_key => token.lexeme)
    tk.location = token.location
    tk
  end

  protected

  attr_reader :strategy

  def search_key
    return :rune if strategy == :runic
    :letter
  end
end
