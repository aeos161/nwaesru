require "time"

class Primus::Analysis::LogEntry
  def initialize(data:)
    @data = owned(data)
    @measurements = @data.fetch("results").map do |entry|
      Primus::Analysis::Result.new(entry.fetch("result"))
    end.freeze
  end

  def with_id(id)
    self.class.new(data: @data.merge("analysis_run_id" => id))
  end

  def completed(results)
    self.class.new(data: @data.merge("status" => "completed",
      "completed_at" => Time.now.utc.iso8601,
      "results" => results.map { |result| result_envelope(result) }))
  end

  def failed(error)
    details = { "type" => error.class.name, "message" => error.message }
    self.class.new(data: @data.merge("status" => "error",
      "completed_at" => Time.now.utc.iso8601, "errors" => [details]))
  end

  def to_h; @data; end
  def analysis_run_id; @data["analysis_run_id"]; end
  def experiment_id; @data.fetch("experiment_id"); end
  def run_id; @data.fetch("run_id"); end
  def status; @data.fetch("status"); end
  def errors; @data.fetch("errors"); end
  def measurements; @measurements; end
  def definition_sha256; @data.fetch("definition_sha256"); end
  def git_head; @data["git_head"]; end
  def ruby_version; @data["ruby_version"]; end
  def started_at; @data["started_at"]; end
  def completed_at; @data["completed_at"]; end
  def output_sha256; @data.dig("observation_output", "sha256"); end
  def provenance_sha256; @data.dig("observation_provenance", "sha256"); end

  def matches_observation?(experiment_id:, run_id:)
    self.experiment_id == experiment_id && self.run_id == run_id
  end

  private

  def result_envelope(result)
    { "declaration_id" => result.declaration_id, "analyzer" => "symbol-statistics",
      "version" => 1, "stage" => "final", "representation" => result.representation,
      "profile" => @data.fetch("representations").fetch(result.representation),
      "exclusions" => "non-GP passthrough literals", "result" => result.to_h }
  end

  def owned(value)
    case value
    when Hash then value.each_with_object({}) { |(key, item), copy| copy[owned(key)] = owned(item) }.freeze
    when Array then value.map { |item| owned(item) }.freeze
    else value.dup.freeze
    end
  end
end
