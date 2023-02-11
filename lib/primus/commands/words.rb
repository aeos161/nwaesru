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
  option :only_english, type: :boolean
  option :only_prime_sums, type: :boolean
  def generate
    n = options[:number_of_characters].to_i
    generator = Primus::Word::Generator.new(number_of_characters: n)
    generator.generate_candidate_strings
    if options[:only_prime_sums]
      generator.limit_to_prime_sums
    end
    generator.expand_strings_to_words
    generator.exclude_invalid_words
    if options[:only_english]
      generator.limit_to_english_words
    end
    candidates = generator.results
    puts "Number of results: #{candidates.size}"
    candidates.each do |word|
      puts word.to_s
    end
  end
end
