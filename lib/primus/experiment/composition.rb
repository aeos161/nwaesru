require "digest"
require "json"

class Primus::Experiment::Composition
  POLICY = "gp-latin-compatibility-v1".freeze

  def initialize(options)
    @options = options
  end

  def experiment
    choices = { "input" => input, "recipe" => { "id" => @options[:recipe] },
                "output" => { "policy" => POLICY }, "checks" => [check] }
    id = "ad-hoc-#{Digest::SHA256.hexdigest(JSON.generate(choices))[0, 16]}"
    Primus::Experiment.from_data({ "schema_version" => 2, "id" => id,
                                   "title" => "Composed experiment",
                                   "purpose" => "Evaluate a selected page and recipe." }.merge(choices))
  end

  private

  def input
    id = @options[:input]
    path = "data/encoded/liber_primus/#{id.to_s.tr('-', '_')}.yml"
    { "id" => id, "sha256" => file_digest(path) }
  end

  def check
    if @options[:hash]
      { "id" => "check-1", "strategy" => "hash",
        "algorithm" => @options[:hash], "expectation" => hash_expectation }
    else
      { "id" => "check-1", "strategy" => "plaintext",
        "expectation" => plaintext_expectation }
    end
  end

  def hash_expectation
    { "digest" => @options[:expect_digest],
      "provenance" => provenance }
  end

  def plaintext_expectation
    path = @options[:expect_text]
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
