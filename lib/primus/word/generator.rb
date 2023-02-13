class Primus::Word::Generator
  attr_reader :alphabet, :dictionary, :number_of_characters, :results

  def initialize(alphabet: nil, number_of_characters:, dictionary: nil)
    @alphabet = alphabet || Primus::GematriaPrimus.instance
    @number_of_characters = number_of_characters
    @identity_map =
      Primus::Ngram::IdentityMap.new(number_of_characters: number_of_characters)
    @results = []
    @dictionary = dictionary || initialize_default_dictionary
  end

  def generate_candidate_strings
    @results =
      alphabet.generate_words(number_of_characters: number_of_characters)
  end

  def limit_to_prime_sums
    @results = results.select { |word| word.sum.prime? }
  end

  def expand_strings_to_words
    @results = results.flat_map do |word|
      expander = Primus::Word::Expander.new(method: :letter)
      expander.visit_word(word)
      expander.results
    end.sort.uniq
  end

  def exclude_invalid_words
    @results = results.select do |word|
      parsed_word = Primus.parse(word).first
      parsed_word.size == number_of_characters
    end
  end

  def limit_to_english_words
    @results = results.select do |word|
      ngram = identity_map.find(word)
      if ngram.nil?
        sleep 1
        lemma = dictionary.lemma(word: word, language: "en", params: {})
        ngram = Primus::Ngram.new(ngram: word, valid: lemma.error.nil?)
        identity_map.store(ngram)
      end
      ngram.valid?
    end
  end

  protected

  attr_reader :identity_map

  def initialize_default_dictionary
    id = ENV["OXFORD_APP_ID"]
    key = ENV["OXFORD_APP_KEY"]
    OxfordDictionary.new(app_id: id, app_key: key)
  end
end
