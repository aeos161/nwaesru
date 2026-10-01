require "active_model"
require "digest"
require "json"
require "psych"

class Primus::Experiment
  include ActiveModel::Model

  class LoadError < StandardError; end

  ID = "page-57-latin".freeze
  SOURCE = "data/encoded/liber_primus/page_57.yml".freeze
  ROOT_KEYS = %w[schema_version id title purpose input operation output
                 expectation].freeze
  NESTED_KEYS = {
    "input" => %w[page_number path sha256],
    "output" => %w[policy],
    "expectation" => %w[kind path sha256 provenance],
  }.freeze

  attr_accessor :schema_version, :id, :title, :purpose, :input, :operation,
                :output, :expectation
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
    required = { schema_version: 1, id: ID, operation: "runes_to_latin" }
    required.each { |field, value|
      reject(field, "must be #{value}") unless public_send(field) == value
    }
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
    expected = { input: { "page_number" => 57, "path" => SOURCE },
                 output: { "policy" => "gp-latin-compatibility-v1" },
                 expectation: { "kind" => "plaintext" } }
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
    provenance = expectation["provenance"] if expectation.is_a?(Hash)
    unless provenance.is_a?(String) && !provenance.strip.empty?
      reject(:expectation,
             "provenance is required")
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
  end

  def validate_files
    @input_bytes = @source_body = @expected_bytes = nil
    validate_source if safe_path?(input_path, :input)
    validate_expectation if safe_path?(expectation_path, :expectation)
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
      reject(:input,
             "body must contain page 57 runes")
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
