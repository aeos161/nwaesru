class Primus::Document::Decoder
  attr_reader :alphabet, :modulus, :key

  attr_accessor :number_of_characters_processed, :skip_sequence

  def initialize(alphabet: nil, modulus: nil, key: nil)
    @alphabet = alphabet || Primus::GematriaPrimus.build
    @modulus = modulus || @alphabet.size
    @number_of_characters_processed = 0
    @skip_sequence = []
    @key = key
  end

  def visit_word(word)
    tokens = word.map { |character| process(character) }
    Primus::Word.new(tokens: tokens)
  end

  def visit_token(token)
    token
  end

  protected

  def decodable?(character)
    !character.index.nil?
  end

  def skip?
    next_index = number_of_characters_processed + 1
    true if (skip_sequence || []).include? next_index
  end

  def process(character)
    return character unless decodable? character
    unless skip?
      character = decode(character)
    end
    increment_characters_processed
    character
  end

  def decode(character)
    raise NoMethodError.new("must implement #decode")
  end

  def increment_characters_processed
    self.number_of_characters_processed += 1
  end
end
