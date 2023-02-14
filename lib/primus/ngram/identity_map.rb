class Primus::Ngram::IdentityMap
  BASE_PATH = "./data/ngrams/english".freeze
  FILE_NAME = "length_%d.yml"

  def initialize(number_of_characters:)
    @valid_file_name = [BASE_PATH, FILE_NAME % number_of_characters].join("/")
    @invalid_file_name = [BASE_PATH, FILE_NAME % number_of_characters].join("/")
    load_valid_ngrams
    load_invalid_ngrams
  end

  def find(ngram)
    find_valid_ngram(ngram) || find_invalid_ngram(ngram)
  end

  def store(ngram)
    return if ngram.persisted?

    if ngram.valid?
      @valid_ngrams << ngram.to_s
      file_name = @valid_file_name
    else
      @invalid_ngrams << ngram.to_s
      file_name = @invalid_file_name
    end

    File.write(file_name, " - \"#{ngram}\"\n", mode: "a")
  end

  protected

  def load_valid_ngrams
    @valid_ngrams ||= Psych.safe_load(File.read(@valid_file_name))["data"] || []
  end

  def load_invalid_ngrams
    @invalid_ngrams ||=
      Psych.safe_load(File.read(@invalid_file_name))["data"] || []
  end

  def find_valid_ngram(ngram)
    return unless @valid_ngrams.include? ngram
    Primus::Ngram.new(ngram: ngram, valid: true, persisted: true)
  end

  def find_invalid_ngram(ngram)
    return unless @invalid_ngrams.include? ngram
    Primus::Ngram.new(ngram: ngram, valid: false, persisted: true)
  end
end
