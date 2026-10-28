class Primus::Analysis::Definition
  class Error < StandardError; end
  ID = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  attr_reader :data, :bytes

  def initialize(path:)
    @bytes = File.binread(path)
    @data = Primus::Analysis::StrictData.yaml(@bytes)
    validate!
  rescue Primus::Analysis::StrictData::Error, Errno::ENOENT => error
    raise Error, error.message
  end

  def declarations
    data.fetch("analyses")
  end

  def stage
    declarations.first.fetch("target").fetch("stage")
  end

  private

  def validate!
    fields!(data, %w[schema_version id analyses])
    raise Error, "schema version must be 1" unless data["schema_version"] == 1
    raise Error, "invalid analysis ID" unless data["id"].is_a?(String) && ID.match?(data["id"])
    validate_declarations!
  end

  def validate_declarations!
    entries = data["analyses"]
    raise Error, "analyses must contain one or two entries" unless entries.is_a?(Array) && (1..2).cover?(entries.size)
    entries.each { |entry| validate_entry!(entry) }
    raise Error, "duplicate analysis id" unless entries.map { |entry| entry["id"] }.uniq.size == entries.size
    raise Error, "duplicate representation" unless entries.map { |entry| entry.dig("target", "representation") }.uniq.size == entries.size
    raise Error, "mixed checkpoint stages" unless entries.map { |entry| entry.dig("target", "stage") }.uniq.size == 1
    raise Error, "mixed analyzer families" unless entries.map { |entry| entry["analyzer"] }.uniq.size == 1
  end

  def validate_entry!(entry)
    keys = %w[id analyzer version target]
    keys << "parameters" if entry.is_a?(Hash) && entry["analyzer"] == "repeated-ngrams"
    fields!(entry, keys)
    raise Error, "invalid declaration id" unless entry["id"].is_a?(String) && ID.match?(entry["id"])
    raise Error, "unsupported analyzer/version" unless %w[symbol-statistics repeated-ngrams].include?(entry["analyzer"]) && entry["version"] == 1
    validate_parameters!(entry) if entry["analyzer"] == "repeated-ngrams"
    fields!(entry["target"], %w[stage representation])
    stage = entry["target"]["stage"]
    raise Error, "unsafe checkpoint stage" unless stage.is_a?(String) && ID.match?(stage) && !stage.match?(/\A\d+\z/)
    unless Primus::Analysis::REPRESENTATIONS.include?(entry["target"]["representation"])
      raise Error, "unsupported representation"
    end
  end

  def validate_parameters!(entry)
    params = entry.fetch("parameters")
    fields!(params, %w[lengths boundary_policy])
    lengths = params.fetch("lengths")
    valid = lengths.is_a?(Array) && !lengths.empty? &&
      lengths.all? { |n| n.instance_of?(Integer) && [2, 3].include?(n) } &&
      lengths == lengths.uniq.sort
    raise Error, "invalid repeated n-gram lengths" unless valid
    raise Error, "unsupported boundary policy" unless params["boundary_policy"] == "continuous-gp-v1"
  end

  def fields!(value, keys)
    raise Error, "expected fields #{keys.join(', ')}" unless value.is_a?(Hash)
    extra = value.keys - keys
    raise Error, "unknown field #{extra.first}" unless extra.empty?
    missing = keys - value.keys
    raise Error, "missing field #{missing.first}" unless missing.empty?
  end
end
