class Primus::Document::StreamCipher
  attr_reader :dictionary

  def initialize(dictionary: nil)
    @dictionary = dictionary || Primus::GematriaPrimus.build
  end

  def visit_word(word)
    tokens = word.map { |char| process(character: char) }
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end

  protected

  def process(character:)
    return character if character.index.nil?
    index = (character.index ^ 47) % 29
    dictionary.find_by(index: index)
  end
end
