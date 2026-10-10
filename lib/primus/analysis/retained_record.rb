class Primus::Analysis::RetainedRecord
  class Error < StandardError; end

  def initialize(data)
    @data = data
  end

  def validate!
    raise Error, "analysis schema version" unless @data["schema_version"] == 1
    raise Error, "analysis observation identity" unless valid_ids?
    raise Error, "analysis status" unless %w[running completed error].include?(@data["status"])
    raise Error, "malformed analysis results" unless @data["results"].is_a?(Array)
    @data["results"].each { |entry| validate_result!(entry) }
  end

  private

  def valid_ids?
    Primus::Analysis::SavedObservation::ID.match?(@data["experiment_id"].to_s) &&
      Primus::Analysis::SavedObservation::RUN_ID.match?(@data["run_id"].to_s) &&
      Primus::Analysis::SavedObservation::RUN_ID.match?(@data["analysis_run_id"].to_s)
  end

  def validate_result!(entry)
    raise Error, "malformed result entry" unless entry.is_a?(Hash)
    raise Error, "invalid result declaration" unless Primus::Analysis::SavedObservation::ID.match?(entry["declaration_id"].to_s)
    raise Error, "invalid representation" unless Primus::Analysis::REPRESENTATIONS.include?(entry["representation"])
    raise Error, "invalid analyzer" unless entry.values_at("analyzer", "version", "stage") == ["symbol-statistics", 1, "final"]
    result = entry["result"]
    raise Error, "malformed measurement" unless result.is_a?(Hash) && result["frequencies"].is_a?(Array) && result["ic"].is_a?(Hash)
    raise Error, "measurement representation mismatch" unless result["representation"] == entry["representation"]
    raise Error, "invalid measurement sample size" unless result["sample_size"].is_a?(Integer) && result["sample_size"] >= 0
  end
end
