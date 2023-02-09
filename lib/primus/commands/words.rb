class Primus::Commands::Words < Primus::Commands::SubCommandBase
  desc "generate", "Generate words"
  option :number_of_characters, type: :string, required: true, aliases: :n
  option :only_english_words, type: :boolean
  option :only_prime_sums, type: :boolean
  def generate
    number_of_characters = options[:number_of_characters].to_i
    gp = Primus::GematriaPrimus.instance
    candidates = gp.generate_words(number_of_characters: number_of_characters)

    if options[:only_prime_sums]
      candidates = candidates.select { |word| word.sum.prime? }
    end

    candidates = candidates.flat_map do |word|
      expander = Primus::Word::Expander.new(method: :letter)
      expander.visit_word(word)
      expander.results
    end

    if options[:only_english_words]
      Linguo.api_key = ENV["LINGUO_API_KEY"]
      # TODO use language detection api
    end

    candidates = candidates.uniq
    puts "Number of results: #{candidates.size}"

    candidates.each do |word|
      puts word.to_s
    end
  end
end
