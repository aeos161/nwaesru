class Primus::Sentence
  include Enumerable

  attr_reader :words

  def initialize(words: [])
    @words = words
  end

  def <<(word)
    @word << word
  end
end
