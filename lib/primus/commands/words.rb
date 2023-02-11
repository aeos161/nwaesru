class Primus::Commands::Words < Primus::Commands::SubCommandBase
  desc "sum", "Get the Gematria Primus sum of a word"
  option :parse_runes, type: :boolean
  def sum(cipher_text)
    parser = options[:parse_runes] ? :rune : :letter
    word_sums = Primus.sum(cipher_text, parser)
    total = word_sums.sum
    puts "Word: #{cipher_text}"
    puts "Letters: #{word_sums.join(', ')}"
    puts "Sum: #{total}"
    puts "Prime: #{total.prime?}"
    puts "Emirp: #{total.emirp?}"
  end

  desc "generate", "Generate words"
  option :number_of_characters, type: :string, required: true, aliases: :n
  option :only_english_words, type: :boolean
  option :only_prime_sums, type: :boolean
  def generate
    generate_candidate_strings
    limit_to_prime_sums_if_applicable
    expand_strings_to_words
    limit_to_english_words_if_applicable
    print_results
  end

  protected

  attr_reader :candidates

  def generate_candidate_strings
    gp = Primus::GematriaPrimus.instance
    number_of_characters = options[:number_of_characters].to_i
    @candidates = gp.generate_words(number_of_characters: number_of_characters)
  end

  def limit_to_prime_sums_if_applicable
    return candidates unless options[:only_prime_sums]
    @candidates = candidates.select { |word| word.sum.prime? }
  end

  def expand_strings_to_words
    @candidates = candidates.flat_map do |word|
      expander = Primus::Word::Expander.new(method: :letter)
      expander.visit_word(word)
      expander.results
    end.uniq
  end

  def limit_to_english_words_if_applicable
    # TODO: use oxford dictionary api
  end

  def print_results
    puts "Number of results: #{candidates.size}"
    candidates.each do |word|
      puts word.to_s
    end
  end
end
