class Primus::LiberPrimus::Parser
  attr_reader :lines, :result

  def initialize(lines: [], word_delimiter: nil, char_delimiter: nil,
                 sentence_delimiter: nil, dictionary: nil)
    @lines = lines
    @result = []
    @sentence_delimiter ||= Primus::LiberPrimus::Page::SENTENCE_DELIMITER
    @word_delimiter ||= Primus::LiberPrimus::Page::WORD_DELIMITER
    @char_delimiter ||= ""
    @dictionary ||= Primus::GematriaPrimus.build
  end

  def parse
    @result = Primus::LiberPrimus::Document.new(words: parse_words)
  end

  protected

  attr_reader :dictionary, :word_delimiter, :char_delimiter, :sentence_delimiter

  def parse_words
    lines.
      join.
      split(sentence_delimiter).
      map(&method(:split_by_word)).
      flatten.
      map(&method(:split_by_char)).
      map(&method(:build_words))
  end

  def split_by_word(string)
    string.split(word_delimiter)
  end

  def split_by_char(string)
    string.split(char_delimiter).map(&:strip)
  end

  def tokenize(char)
    dictionary.find_by(rune: char)
  end

  def build_words(word)
    Primus::LiberPrimus::Word.new(tokens: word.map(&method(:tokenize)))
  end
end
