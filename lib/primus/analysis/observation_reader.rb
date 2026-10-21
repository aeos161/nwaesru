require "digest"

class Primus::Analysis::ObservationReader
  class Error < StandardError; end
  COORDINATES = %w[page_number occurrence byte_start byte_end character_start
                   character_end line column rune_index].freeze

  def initialize(output_path:, experiment_id:, run_id:, stage: "final")
    @output_path, @experiment_id, @run_id, @stage = output_path, experiment_id, run_id, stage
  end

  def to_observation
    read_record!
    checkpoint_evidence = verified_checkpoint_evidence
    @checkpoint = selected_checkpoint(checkpoint_evidence)
    load_projection!(checkpoint_evidence)
    verified_observation
  rescue Primus::Analysis::StrictData::Error, Errno::ENOENT,
         Errno::ENOTDIR, KeyError, TypeError,
         Primus::Experiment::CheckpointEvidence::Invalid => error
    raise Error, error.message
  end

  private

  attr_reader :record, :profiles, :output_bytes, :directory

  def read_record!
    raise Error, "invalid experiment ID" unless Primus::Analysis::ID.match?(@experiment_id)
    raise Error, "invalid run ID" unless Primus::Analysis::RUN_ID.match?(@run_id)
    @recorded_directory = File.expand_path(File.join(@output_path, @experiment_id, @run_id))
    @directory = File.realpath(@recorded_directory)
    root = File.realpath(@output_path)
    raise Error, "selected run escapes output root" unless @directory.start_with?("#{root}/")
    record_path = File.join(@directory, "record.json")
    raise Error, "record path escapes run" unless File.realpath(record_path) == record_path
    @record_bytes = File.binread(record_path)
    @record = Primus::Analysis::StrictData.json(@record_bytes)
    validate_record!
  end

  def verified_checkpoint_evidence
    evidence_path = File.join(@recorded_directory, "record.json")
    evidence = Primus::Experiment::CheckpointEvidence.new(record_path: evidence_path, data: record)
    evidence.verify!
    evidence
  end

  def load_projection!(evidence)
    if @checkpoint["id"] == record["final_checkpoint_id"]
      load_final_projection!(evidence)
    else
      @output_bytes = @checkpoint.fetch("output_bytes")
      @profiles = checkpoint_profiles
    end
    nil
  end

  def load_final_projection!(evidence)
    @output_bytes = evidence.final_output_bytes
    @rows = Primus::Analysis::StrictData.json(artifact_bytes("provenance.json"))
    validate_profiles! if @stage == "final"
    validate_rows!
    raise Error, "final projection disagrees with checkpoint" unless
      @rows.map { |row| row.fetch("decoded_rune") } == @checkpoint.fetch("symbols_rows").map { |row| row.fetch("rune") }
    @profiles = @stage == "final" ? bound_profiles : checkpoint_profiles
    nil
  end

  def symbols(representation)
    runes = @checkpoint.fetch("symbols_rows").map { |row| row.fetch("rune") }
    return runes if representation == "gp-runes-v1"
    runes.flat_map { |rune| Primus::Analysis::MAP.fetch(rune).chars }
  end

  def verified_observation
    Primus::Analysis::Observation.new(
      experiment_id: @experiment_id, run_id: @run_id, directory: directory,
      symbols_by_representation: Primus::Analysis::REPRESENTATIONS.to_h { |name| [name, symbols(name)] },
      profiles: profiles, evidence: evidence,
    )
  end

  def evidence
    { "observation_record_sha256" => Digest::SHA256.hexdigest(@record_bytes),
      "observation_output" => record.dig("artifacts", "output.txt"),
      "observation_provenance" => record.dig("artifacts", "provenance.json"),
      "representations" => profiles,
      "output_policy" => record.dig("configuration", "output", "policy"),
      "checkpoint" => @checkpoint.reject { |key, _| %w[output_bytes symbols_rows lexemes_rows].include?(key) }.
        merge("requested_stage" => @stage) }
  end

  def selected_checkpoint(evidence)
    step = if @stage == "final"
             id = record["final_checkpoint_id"]
             raise Error, "uncaptured final checkpoint" unless id
             item = record.fetch("checkpoints").find { |candidate| candidate["id"] == id }
             raise Error, "missing final checkpoint" unless item
             item.fetch("step_id")
           else
             @stage
           end
    evidence.checkpoint(step)
  end

  def checkpoint_profiles
    rows = @checkpoint.fetch("symbols_rows")
    common = profile_identity.merge("schema_version" => 1, "stage" => @stage,
               "artifact" => "symbols.json", "symbol_field" => "rune",
               "output_sha256" => @checkpoint.dig("output", "sha256"))
    { "gp-runes-v1" => common.merge("alphabet" => Primus::Analysis::RUNES,
                                    "sample_size" => rows.size),
      "gp-expanded-latin-v1" => common.merge("alphabet" => Primus::Analysis::LATIN,
        "sample_size" => symbols("gp-expanded-latin-v1").size,
        "expansion_map" => Primus::Analysis::MAP) }
  end

  def bound_profiles
    profiles.transform_values { |profile| profile.merge(profile_identity) }
  end

  def profile_identity
    { "checkpoint_id" => @checkpoint.fetch("id"),
      "step_id" => @checkpoint.fetch("step_id"),
      "ordinal" => @checkpoint.fetch("ordinal"),
      "symbols_sha256" => @checkpoint.dig("symbols", "sha256"),
      "lexemes_sha256" => @checkpoint.dig("lexemes", "sha256") }
  end

  def validate_record!
    raise Error, "record identity mismatch" unless record["experiment_id"] == @experiment_id && record["run_id"] == @run_id
    raise Error, "unsupported record schema version" unless [1, 2].include?(record["schema_version"])
    raise Error, "running or unfinished observation" if record["status"] == "running" || !record["completed_at"]
    if record["final_checkpoint_id"] && !record["observation"].is_a?(Hash)
      raise Error, "missing observation"
    end
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
    raise Error, "#{name} bytes mismatch" unless metadata["bytes"] == bytes.bytesize
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
    if @stage == "final"
      raise Error, "rune sample size mismatch" unless profiles.dig("gp-runes-v1", "sample_size") == @rows.size
      raise Error, "Latin sample size mismatch" unless profiles.dig("gp-expanded-latin-v1", "sample_size") == symbols("gp-expanded-latin-v1").size
    end
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
