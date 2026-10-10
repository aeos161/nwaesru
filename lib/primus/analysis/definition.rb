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

  private

  def validate!
    fields!(data, %w[schema_version id analyses])
    raise Error, "schema version must be 1" unless data["schema_version"] == 1
    raise Error, "invalid analysis ID" unless ID.match?(data["id"].to_s)
    validate_declarations!
  end

  def validate_declarations!
    entries = data["analyses"]
    raise Error, "analyses must contain one or two entries" unless entries.is_a?(Array) && (1..2).cover?(entries.size)
    entries.each { |entry| validate_entry!(entry) }
    raise Error, "duplicate analysis id" unless entries.map { |entry| entry["id"] }.uniq.size == entries.size
    raise Error, "duplicate representation" unless entries.map { |entry| entry.dig("target", "representation") }.uniq.size == entries.size
  end

  def validate_entry!(entry)
    fields!(entry, %w[id analyzer version target])
    raise Error, "invalid declaration id" unless ID.match?(entry["id"].to_s)
    raise Error, "unsupported analyzer/version" unless entry["analyzer"] == "symbol-statistics" && entry["version"] == 1
    fields!(entry["target"], %w[stage representation])
    raise Error, "unsupported stage" unless entry["target"]["stage"] == "final"
    unless Primus::Analysis::REPRESENTATIONS.include?(entry["target"]["representation"])
      raise Error, "unsupported representation"
    end
  end

  def fields!(value, keys)
    raise Error, "expected fields #{keys.join(', ')}" unless value.is_a?(Hash)
    extra = value.keys - keys
    raise Error, "unknown field #{extra.first}" unless extra.empty?
    missing = keys - value.keys
    raise Error, "missing field #{missing.first}" unless missing.empty?
  end
end
