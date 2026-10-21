class Primus::Analysis::RecordValidator
  class Error < StandardError; end
  CHECKPOINT_ID = /\A[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/

  def initialize(data)
    @data = data
  end

  def validate!
    raise Error, "analysis schema version" unless @data["schema_version"] == 1
    raise Error, "analysis observation identity" unless valid_ids?
    raise Error, "analysis status" unless %w[running completed error].include?(@data["status"])
    raise Error, "malformed analysis results" unless @data["results"].is_a?(Array)
    validate_checkpoint! if @data["checkpoint"] || @data["status"] == "completed"
    @data["results"].each { |entry| validate_result!(entry) }
    nil
  end

  private

  def valid_ids?
    Primus::Analysis::ID.match?(@data["experiment_id"].to_s) &&
      Primus::Analysis::RUN_ID.match?(@data["run_id"].to_s) &&
      Primus::Analysis::RUN_ID.match?(@data["analysis_run_id"].to_s)
  end

  def validate_result!(entry)
    raise Error, "malformed result entry" unless entry.is_a?(Hash)
    raise Error, "invalid result declaration" unless Primus::Analysis::ID.match?(entry["declaration_id"].to_s)
    raise Error, "invalid representation" unless Primus::Analysis::REPRESENTATIONS.include?(entry["representation"])
    raise Error, "invalid analyzer" unless entry.values_at("analyzer", "version", "stage") ==
      ["symbol-statistics", 1, @data.dig("checkpoint", "requested_stage")]
    raise Error, "checkpoint identity mismatch" unless entry["checkpoint_id"] == @data.dig("checkpoint", "id")
    raise Error, "checkpoint step mismatch" unless entry["checkpoint_step_id"] == @data.dig("checkpoint", "step_id")
    profile = entry["profile"]
    raise Error, "profile mismatch" unless profile == @data.dig("representations", entry["representation"])
    raise Error, "profile stage mismatch" unless profile.is_a?(Hash) &&
      profile["stage"] == entry["stage"]
    checkpoint = @data.fetch("checkpoint")
    raise Error, "profile checkpoint mismatch" unless
      profile.values_at("checkpoint_id", "step_id", "ordinal") ==
      checkpoint.values_at("id", "step_id", "ordinal")
    raise Error, "profile output mismatch" unless
      profile["output_sha256"] == checkpoint.dig("output", "sha256")
    raise Error, "profile symbols mismatch" unless
      profile["symbols_sha256"] == checkpoint.dig("symbols", "sha256")
    raise Error, "profile lexemes mismatch" unless
      profile["lexemes_sha256"] == checkpoint.dig("lexemes", "sha256")
    result = entry["result"]
    raise Error, "malformed measurement" unless result.is_a?(Hash) && result["frequencies"].is_a?(Array) && result["ic"].is_a?(Hash)
    raise Error, "measurement representation mismatch" unless result["representation"] == entry["representation"]
    raise Error, "invalid measurement sample size" unless result["sample_size"].is_a?(Integer) && result["sample_size"] >= 0
    Primus::Analysis::ICInterpretationValidator.new(result).validate! if result.key?("interpretation")
  end

  def validate_checkpoint!
    item = @data["checkpoint"]
    raise Error, "missing checkpoint identity" unless item.is_a?(Hash)
    stage = item["requested_stage"]
    raise Error, "invalid checkpoint selector" unless stage.is_a?(String) &&
      Primus::Analysis::ID.match?(stage)
    raise Error, "invalid checkpoint step" unless item["step_id"].is_a?(String) &&
      Primus::Analysis::ID.match?(item["step_id"])
    if stage == "final" && item["step_id"] == "original"
      raise Error, "invalid final checkpoint"
    end
    raise Error, "selector and checkpoint disagree" if stage != "final" && stage != item["step_id"]
    raise Error, "invalid checkpoint UUID" unless item["id"].is_a?(String) &&
      CHECKPOINT_ID.match?(item["id"])
    raise Error, "invalid checkpoint ordinal" unless item["ordinal"].is_a?(Integer) &&
      item["ordinal"] >= 0
    raise Error, "invalid checkpoint operation" unless
      %w[capture totient latin].include?(item["operation"]) && item["parameters"].is_a?(Hash)
    raise Error, "invalid checkpoint parent" unless
      (item["ordinal"].zero? && item["parent_id"].nil?) ||
      (item["ordinal"].positive? && CHECKPOINT_ID.match?(item["parent_id"].to_s))
    validate_checkpoint_policy!(item)
    %w[output symbols lexemes].each { |name| validate_artifact!(item, name) }
  end

  def validate_checkpoint_policy!(item)
    operation = item.fetch("operation")
    expected = operation == "latin" ? %w[gp-latin-compatibility-v1 latin] :
      %w[gp-runes-lossless-v1 gp-runes]
    raise Error, "checkpoint policy mismatch" unless
      item.values_at("policy", "representation") == expected
    raise Error, "original checkpoint mismatch" if item["step_id"] == "original" &&
      (item["ordinal"] != 0 || operation != "capture")
    raise Error, "final checkpoint mismatch" if item["requested_stage"] == "final" &&
      operation != "latin"
  end

  def validate_artifact!(item, name)
    artifact = item[name]
    filename = name == "output" ? "output.txt" : "#{name}.json"
    suffix = "/checkpoints/#{item.fetch('step_id')}/#{filename}"
    raise Error, "invalid selected artifact" unless artifact.is_a?(Hash) &&
      artifact["path"].is_a?(String) && artifact["path"].start_with?("/") &&
      artifact["path"].end_with?(suffix) &&
      artifact["bytes"].is_a?(Integer) && artifact["bytes"] >= 0 &&
      artifact["sha256"].is_a?(String) && artifact["sha256"].match?(/\A[0-9a-f]{64}\z/)
  end
end
