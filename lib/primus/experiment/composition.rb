require "digest"
require "json"

class Primus::Experiment::Composition
  POLICY = "gp-latin-compatibility-v1".freeze

  def initialize(options)
    @options = options
  end

  def experiment
    choices = { "input" => input, "recipe" => recipe,
                "output" => { "policy" => POLICY }, "checks" => checks }
    id = "ad-hoc-#{Digest::SHA256.hexdigest(JSON.generate(choices))[0, 16]}"
    Primus::Experiment.from_data({ "schema_version" => 2, "id" => id,
                                   "title" => "Composed experiment",
                                   "purpose" => "Evaluate a selected page and recipe." }.merge(choices))
  end

  private

  def recipe
    supplied = values(:recipe_param)
    raise Primus::Experiment::LoadError, "parameters require a recipe" if supplied.any? && !@options[:recipe]
    selected = { "id" => @options[:recipe] }
    selected["parameters"] = parsed_parameters(supplied) if supplied.any?
    Primus::Experiment.canonical_recipe(selected)
  end

  def parsed_parameters(supplied)
    supplied.each_with_object({}) do |item, result|
      key, separator, encoded = item.to_s.partition("=")
      raise Primus::Experiment::LoadError, "recipe parameter must be KEY=JSON_VALUE" if key.empty? || separator.empty? || encoded.empty?
      raise Primus::Experiment::LoadError, "duplicate recipe parameter: #{key}" if result.key?(key)
      result[key] = JSON.parse(encoded)
    rescue JSON::ParserError => error
      raise Primus::Experiment::LoadError, "invalid recipe parameter JSON: #{error.message}"
    end
  end

  def input
    id = @options[:input]
    path = "data/encoded/liber_primus/#{id.to_s.tr('-', '_')}.yml"
    { "id" => id, "sha256" => file_digest(path) }
  end

  def checks
    hashes = values(:hash)
    digests = values(:expect_digest)
    validate_choices!(hashes, digests)
    selected = hashes.map { |algorithm| hash_check(algorithm, digests) }
    selected << plaintext_check if values(:expect_text).one?
    selected.each_with_index { |check, index| check["id"] = "check-#{index + 1}" }
    selected
  end

  def values(key)
    value = @options[key]
    value.nil? ? [] : Array(value)
  end

  def validate_choices!(hashes, digests)
    raise Primus::Experiment::LoadError, "duplicate hash algorithm" if hashes.uniq != hashes
    raise Primus::Experiment::LoadError, "repeated plaintext expectation" if values(:expect_text).size > 1
    raise Primus::Experiment::LoadError, "digest without hash" if hashes.empty? && digests.any?
    return if hashes.empty?
    bare = digests.reject { |digest| digest.to_s.include?("=") }
    qualified = digests - bare
    valid = (bare.one? && qualified.empty?) || (bare.empty? && qualified.size == hashes.size && qualified.map { |item| item.split("=", 2).first }.sort == hashes.sort)
    raise Primus::Experiment::LoadError, "ambiguous digest expectations" unless valid
  end

  def hash_check(algorithm, digests)
    digest = digests.one? && !digests.first.to_s.include?("=") ? digests.first : digests.find { |item| item.to_s.start_with?("#{algorithm}=") }.to_s.split("=", 2).last
    { "strategy" => "hash", "algorithm" => algorithm,
      "expectation" => { "digest" => digest, "provenance" => provenance } }
  end

  def plaintext_check
    { "strategy" => "plaintext", "expectation" => plaintext_expectation }
  end

  def plaintext_expectation
    path = values(:expect_text).first
    { "path" => path, "sha256" => file_digest(path),
      "provenance" => provenance }
  end

  def provenance
    @options[:expect_provenance] || "User-supplied CLI expectation."
  end

  def file_digest(path)
    return nil unless path.is_a?(String) && safe_file?(path)
    Digest::SHA256.file(path).hexdigest
  end

  def safe_file?(path)
    return false if path.start_with?("/") || path.split("/").include?("..")
    File.file?(path) && File.realpath(path).start_with?("#{Dir.pwd}/")
  end
end
