require "active_model"
require "digest"
require "json"
require "psych"

class Primus::Experiment
  include ActiveModel::Model

  class LoadError < StandardError; end

  RECIPES = {
    "page-57-latin" => [57, "data/encoded/liber_primus/page_57.yml",
                        "runes_to_latin"],
    "page-57-latin-sha512" => [57, "data/encoded/liber_primus/page_57.yml",
                               "runes_to_latin"],
    "page-57-latin-blake2b512" => [57, "data/encoded/liber_primus/page_57.yml",
                                   "runes_to_latin"],
    "page-57-latin-blake512" => [57, "data/encoded/liber_primus/page_57.yml",
                                "runes_to_latin"],
    "page-56-totient-latin" => [56, "data/encoded/liber_primus/page_56.yml",
                                "totient_shift_to_latin"],
  }.freeze
  TOTIENT_PARAMETERS = { "modulus" => 29, "prime_start" => 2,
                         "skip_sequence" => [56] }.freeze
  ROOT_KEYS = %w[schema_version id title purpose input operation output
                 expectation parameters].freeze
  NESTED_KEYS = {
    "input" => %w[page_number path sha256],
    "output" => %w[policy],
  }.freeze
  EXPECTATION_KEYS = {
    "plaintext" => %w[kind path sha256 provenance],
    "hash" => %w[kind algorithm digest provenance],
  }.freeze
  HASH_ALGORITHMS = {
    "page-57-latin-sha512" => "sha512",
    "page-57-latin-blake2b512" => "blake2b512",
    "page-57-latin-blake512" => "blake512",
  }.freeze

  attr_accessor :schema_version, :id, :title, :purpose, :input, :operation,
                :output, :expectation, :parameters
  attr_reader :definition_path, :definition_bytes, :definition_data,
              :input_bytes, :source_body, :expected_bytes

  def self.load(path:)
    bytes = File.binread(path).force_encoding(Encoding::UTF_8)
    unless bytes.valid_encoding?
      raise LoadError,
            "#{path}: invalid UTF-8 definition"
    end
    tree = Psych.parse_stream(bytes)
    reject_duplicate_keys!(tree)
    data = Psych.safe_load(bytes, aliases: false)
    unless data.is_a?(Hash)
      raise LoadError,
            "#{path}: definition must be a mapping"
    end
    attributes = data.slice(*ROOT_KEYS)
    new(**attributes.transform_keys(&:to_sym)).tap do |model|
      model.instance_variable_set(:@definition_path, path)
      model.instance_variable_set(:@definition_bytes, bytes)
      model.instance_variable_set(:@definition_data, data)
    end
  rescue Psych::Exception, Errno::ENOENT, Errno::EACCES => error
    raise LoadError, "#{path}: #{error.class}: #{error.message}"
  end

  def self.reject_duplicate_keys!(node)
    if node.is_a?(Psych::Nodes::Mapping)
      keys = node.children.each_slice(2).map(&:first).map(&:value)
      if keys.uniq.size != keys.size
        raise LoadError,
              "duplicate YAML key: #{keys.tally.key(2)}"
      end
    end
    if node.respond_to?(:children)
      Array(node.children).each { |child|
        reject_duplicate_keys!(child)
      }
    end
  end

  validate :validate_definition
  validate :validate_files

  def input_path
    input["path"] if input.is_a?(Hash)
  end

  def expectation_path
    expectation["path"] if expectation.is_a?(Hash)
  end

  def source_digest
    Digest::SHA256.hexdigest(input_bytes) if input_bytes
  end

  def expectation_digest
    Digest::SHA256.hexdigest(expected_bytes) if expected_bytes
  end

  def check_details
    errors.objects.map do |error|
      { "stage" => error.options[:stage] || "configuration",
        "type" => error.options[:type] || "ValidationError",
        "message" => error.full_message }
    end
  end

  private

  def validate_definition
    reject(:schema_version, "must be 1") unless schema_version == 1
    validate_recipe
    validate_parameters
    unless title.is_a?(String) && !title.strip.empty?
      reject(:title,
             "is required")
    end
    unless purpose.is_a?(String) && !purpose.strip.empty?
      reject(:purpose,
             "is required")
    end
    validate_mappings
    validate_unknown_fields
  end

  def validate_mappings
    expected = { output: { "policy" => "gp-latin-compatibility-v1" } }
    expected.each do |field, fields|
      value = public_send(field)
      reject(field, "must be a mapping") unless value.is_a?(Hash)
      fields.each { |key, wanted|
        unless value.is_a?(Hash) && value[key] == wanted
          reject(field,
                 "#{key} must be #{wanted}")
        end
      }
    end
    validate_expectation_mapping
    provenance = expectation["provenance"] if expectation.is_a?(Hash)
    unless provenance.is_a?(String) && !provenance.strip.empty?
      reject(:expectation,
             "provenance is required")
    end
  end

  def validate_expectation_mapping
    unless expectation.is_a?(Hash)
      reject(:expectation, "must be a mapping")
      return
    end
    algorithm = HASH_ALGORITHMS[id]
    wanted = algorithm ? "hash" : "plaintext"
    unless expectation["kind"] == wanted
      reject(:expectation, "kind must be #{wanted}")
    end
    return unless wanted == "hash"
    unless expectation["algorithm"] == algorithm
      reject(:expectation, "algorithm must be #{algorithm}")
    end
    digest = expectation["digest"]
    valid_digest = digest.is_a?(String) && digest.match?(/\A[0-9a-f]{128}\z/)
    reject(:expectation, "digest must be 128 lowercase hex") unless valid_digest
  end

  def validate_recipe
    recipe = RECIPES[id]
    unless recipe && input.is_a?(Hash) &&
        input["page_number"].instance_of?(Integer) &&
        recipe == [input["page_number"], input["path"], operation]
      reject(:base, "unsupported page, path, ID, or operation combination")
    end
    reject(:input, "must be a mapping") unless input.is_a?(Hash)
  end

  def validate_parameters
    if id == "page-56-totient-latin"
      valid = parameters.is_a?(Hash) &&
        parameters.keys.sort == TOTIENT_PARAMETERS.keys.sort &&
        parameters.all? { |key, value| parameter_matches?(key, value) }
      reject(:parameters, "must match the page 56 recipe") unless valid
    elsif !parameters.nil? || definition_data.key?("parameters")
      reject(:parameters, "are unsupported for this recipe")
    end
  end

  def parameter_matches?(key, value)
    expected = TOTIENT_PARAMETERS[key]
    if expected.is_a?(Array)
      value.is_a?(Array) && value == expected &&
        value.first.instance_of?(Integer)
    else
      value.instance_of?(Integer) && value == expected
    end
  end

  def validate_unknown_fields
    if (definition_data.keys - ROOT_KEYS).any?
      reject(:base,
             "unknown fields: #{(definition_data.keys - ROOT_KEYS).join(", ")}")
    end
    NESTED_KEYS.each do |field, allowed|
      actual = public_send(field)
      if actual.is_a?(Hash) && (actual.keys - allowed).any?
        reject(field,
               "unknown fields: #{(actual.keys - allowed).join(", ")}")
      end
    end
    if expectation.is_a?(Hash)
      allowed = EXPECTATION_KEYS[expectation["kind"]] || []
      extra = expectation.keys - allowed
      reject(:expectation, "unknown fields") if extra.any?
    end
  end

  def validate_files
    @input_bytes = @source_body = @expected_bytes = nil
    validate_source if safe_path?(input_path, :input)
    if expectation.is_a?(Hash) && expectation["kind"] == "plaintext" &&
        safe_path?(expectation_path, :expectation)
      validate_expectation
    end
  end

  def safe_path?(path, field)
    unless path.is_a?(String) && !path.empty? && !path.start_with?("/") &&
        path.split("/").exclude?("..") &&
        File.expand_path(path).start_with?("#{Dir.pwd}/") &&
        (!File.exist?(path) || File.realpath(path).start_with?("#{Dir.pwd}/"))
      reject(field, "path must stay inside repository")
      return false
    end
    true
  end

  def validate_source
    @input_bytes = File.binread(input_path).force_encoding(Encoding::UTF_8)
    unless input_bytes.valid_encoding?
      reject(:input, "invalid UTF-8",
             stage: "configuration")
    end
    return unless input_bytes.valid_encoding?
    body = Psych.safe_load(input_bytes, aliases: false)
    @source_body = body["body"] if body.is_a?(Hash) &&
      body["body"].is_a?(String)
    unless source_body.is_a?(String) && source_body.match?(/[ᚠ-ᛟ]/)
      reject(:input, "body must contain GP runes")
    end
    verify_digest(input, source_digest, :input)
  rescue Psych::Exception, SystemCallError => error
    reject(:input, "#{input_path}: #{error.message}", stage: "configuration",
                                                      type: error.class.name)
  end

  def validate_expectation
    @expected_bytes = File.binread(expectation_path).force_encoding(Encoding::UTF_8)
    reject(:expectation, "invalid UTF-8") unless expected_bytes.valid_encoding?
    verify_digest(expectation, expectation_digest, :expectation)
  rescue SystemCallError => error
    reject(:expectation, "#{expectation_path}: #{error.message}",
           type: error.class.name)
  end

  def verify_digest(config, actual, field)
    declared = config["sha256"]
    valid_digest = declared.is_a?(String) &&
      declared.match?(/\A[0-9a-f]{64}\z/)
    return if valid_digest && declared == actual
    reject(field, "SHA-256 digest does not match", stage: "integrity")
  end

  def reject(field, message, stage: "configuration", type: "ValidationError")
    errors.add(field, message, stage: stage, type: type)
  end
end
