class Primus::Commands::Brute < Primus::Commands::SubCommandBase
  class_option :parse_runes, type: :boolean

  desc "crib", "Generate candidate english words/phrases for cipher text"
  option :require_prime_sum, type: :boolean
  option :break_at, type: :numeric
  option :paralellism, type: :numeric
  def crib(cipher_text_input)
    paralellism = options.fetch(:paralellism, 5)
    break_at = options[:break_at]

    @cipher_text = parse(cipher_text_input)
    assert_ngram_size_is_supported!
    @bi_grams = load_bi_grams
    @tri_grams = load_tri_grams

    phrases = []

    @tri_grams.each do |word0|
      @bi_grams.each do |word1|
        @tri_grams.each do |word2|
          phrases << [word0, word1, word2]
          break if break_at && phrases.size >= break_at
        end
        break if break_at && phrases.size >= break_at
      end
      break if break_at && phrases.size >= break_at
    end

    chunks = phrases.each_slice(phrases.size / paralellism.to_f)
    @candidates = []
    threads = []

    chunks.each do |chunk|
      threads << Thread.new do
        result = chunk.select { |phrase| phrase.map(&:gp_sum).sum.prime? }
        @candidates.concat(result)
      end
    end

    threads.each(&:join)

    puts "Cipher Text: #{cipher_text.join(" ")}"
    puts "Number of Results: #{@candidates.size}"
    puts @candidates.map { |phrase| phrase.join(" ") + "." }
  end

  desc "key", "Generate a key to satisfy cipher text"
  option :plain_text, type: :string, required: true, repeatable: true
  option :reverse, type: :boolean
  def key(cipher_text)
    cipher_text = parse(cipher_text).first
    if options[:reverse]
      cipher_text = cipher_text.reverse
    end
    plain_text_options = Primus.parse(options[:plain_text])
    plain_text_options.each do |plain_text|
      key = cipher_text - plain_text
      puts "#{cipher_text.to_s(:letter)} to #{plain_text.to_s(:letter)} => Key: #{key.to_s(:letter)}"
    end
  end

  protected

  attr_reader :cipher_text

  def parse(cipher_text)
    parser = options[:parse_runes] ? :rune : :letter
    Primus.parse(cipher_text, parser)
  end

  def assert_ngram_size_is_supported!
    return if cipher_text.map(&:size).reject { |n| (2..3).cover? n }.none?
    fail "Only 2 or 3 letter n-grams are currently supported"
  end

  def load_bi_grams
    path = "./data/lexicon/english_word_gp_bi_grams.yml"
    Psych.safe_load(File.read(path))["data"]
  end

  def load_tri_grams
    path = "./data/lexicon/english_word_gp_tri_grams.yml"
    Psych.safe_load(File.read(path))["data"]
  end
end
