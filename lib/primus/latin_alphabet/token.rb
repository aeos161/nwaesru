class Primus::LatinAlphabet::Token
  attr_reader :index, :letter

  attr_accessor :location

  def initialize(index: nil, letter:)
    @index = index
    @letter = letter
  end

  def ==(token)
    index == token.index && letter == token.letter
  end

  def to_s(*)
    letter.to_s
  end
end
