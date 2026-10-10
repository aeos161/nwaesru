require "digest"

class Primus::Analysis::SavedObservation
  class Error < StandardError; end
  ID = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
  RUN_ID = /\A[0-9]{8}T[0-9]{6}-[a-f0-9]{12}\z/
  COORDINATES = %w[page_number occurrence byte_start byte_end character_start
                   character_end line column rune_index].freeze

  attr_reader :record, :record_bytes, :profiles, :output_bytes, :provenance_bytes,
              :directory, :experiment_id, :run_id

  def initialize(output_path:, experiment_id:, run_id:)
    @experiment_id, @run_id = experiment_id, run_id
    raise Error, "invalid experiment ID" unless ID.match?(experiment_id)
    raise Error, "invalid run ID" unless RUN_ID.match?(run_id)
    @recorded_directory = File.expand_path(File.join(output_path, experiment_id, run_id))
    @directory = File.realpath(@recorded_directory)
    @record_bytes = File.binread(File.join(@directory, "record.json"))
    @record = Primus::Analysis::StrictData.json(@record_bytes)
    validate_record!
    @output_bytes = artifact_bytes("output.txt")
    @provenance_bytes = artifact_bytes("provenance.json")
    @rows = Primus::Analysis::StrictData.json(@provenance_bytes)
    validate_profiles!
    validate_rows!
  rescue Primus::Analysis::StrictData::Error, Errno::ENOENT,
         Errno::ENOTDIR, KeyError, TypeError => error
    raise Error, error.message
  end

  def symbols(representation)
    runes = @rows.map { |row| row.fetch("decoded_rune") }
    return runes if representation == "gp-runes-v1"
    runes.flat_map { |rune| Primus::Analysis::MAP.fetch(rune).chars }
  end

  private

  def validate_record!
    raise Error, "record identity mismatch" unless record["experiment_id"] == experiment_id && record["run_id"] == run_id
    raise Error, "unsupported record schema version" unless [1, 2].include?(record["schema_version"])
    raise Error, "running or unfinished observation" if record["status"] == "running" || !record["completed_at"]
    raise Error, "missing observation" unless record["observation"].is_a?(Hash)
    unless record.dig("configuration", "output", "policy") == "gp-latin-compatibility-v1"
      raise Error, "unsupported output policy"
    end
  end

  def artifact_bytes(name)
    metadata = record.fetch("artifacts").fetch(name)
    path = File.expand_path(metadata.fetch("path"))
    expected = File.join(@recorded_directory, name)
    raise Error, "#{name} path mismatch" unless path == expected
    raise Error, "#{name} symlink escapes run" unless File.realpath(path) == File.join(directory, name)
    bytes = File.binread(path)
    raise Error, "#{name} byte count mismatch" unless metadata["bytes"] == bytes.bytesize
    raise Error, "#{name} SHA-256 mismatch" unless metadata["sha256"] == Digest::SHA256.hexdigest(bytes)
    bytes
  end

  def validate_profiles!
    @profiles = record.dig("observation", "representations")
    raise Error, "missing representation manifest; recreate the run" unless profiles.is_a?(Hash)
    raise Error, "output byte count mismatch" unless record.dig("observation", "output_bytes") == output_bytes.bytesize
    Primus::Analysis::StrictData.utf8(output_bytes)
    Primus::Analysis::REPRESENTATIONS.each { |name| validate_profile!(name) }
  end

  def validate_profile!(name)
    profile = profiles.fetch(name)
    expected_alphabet = name == "gp-runes-v1" ? Primus::Analysis::RUNES : Primus::Analysis::LATIN
    raise Error, "#{name} schema version" unless profile["schema_version"] == 1
    raise Error, "#{name} final provenance contract" unless profile.values_at("stage", "artifact", "symbol_field") == %w[final provenance.json decoded_rune]
    raise Error, "#{name} alphabet mismatch" unless profile["alphabet"] == expected_alphabet
    raise Error, "#{name} output digest mismatch" unless profile["output_sha256"] == record.dig("artifacts", "output.txt", "sha256")
    raise Error, "#{name} provenance digest mismatch" unless profile["provenance_sha256"] == record.dig("artifacts", "provenance.json", "sha256")
    if name == "gp-expanded-latin-v1"
      raise Error, "canonical expansion map mismatch" unless profile["expansion_map"] == Primus::Analysis::MAP
    end
  end

  def validate_rows!
    raise Error, "provenance must be an array" unless @rows.is_a?(Array)
    @rows.each_with_index { |row, index| validate_row!(row, index) }
    identities = @rows.map { |row| row.values_at("page_number", "occurrence", "rune_index") }
    raise Error, "duplicate source identity" unless identities.uniq.size == identities.size
    raise Error, "rune sample size mismatch" unless profiles.dig("gp-runes-v1", "sample_size") == @rows.size
    raise Error, "Latin sample size mismatch" unless profiles.dig("gp-expanded-latin-v1", "sample_size") == symbols("gp-expanded-latin-v1").size
  end

  def validate_row!(row, index)
    raise Error, "invalid provenance row" unless row.is_a?(Hash)
    raise Error, "provenance ordinal mismatch" unless row["ordinal"] == index
    raise Error, "missing source coordinates" unless COORDINATES.all? { |key| row[key].is_a?(Integer) }
    rune = row["decoded_rune"]
    raise Error, "invalid decoded rune symbol" unless Primus::Analysis::MAP.key?(rune)
    raise Error, "Latin expansion contradiction" unless row["latin"] == Primus::Analysis::MAP.fetch(rune)
    raise Error, "missing original rune" unless row["rune"].is_a?(String)
  end
end
