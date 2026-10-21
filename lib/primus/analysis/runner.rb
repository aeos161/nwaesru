require "open3"

class Primus::Analysis::Runner
  attr_reader :log_entry

  def initialize(definition:, observation:)
    @definition, @observation = definition, observation
    @store = Primus::Analysis::Store.new(directory: observation.directory)
    @log_entry = nil
  end

  def run
    results = @definition.declarations.map { |entry| result_for(entry) }
    @log_entry = @store.reserve(
      Primus::Analysis::LogEntry.new(data: initial_data), @definition.bytes,
    )
    @log_entry = @store.finish(@log_entry.completed(results))
    nil
  rescue StandardError => error
    @log_entry = @store.finish(@log_entry.failed(error)) if @log_entry&.status == "running"
    raise
  end

  private

  def result_for(entry)
    name = entry.fetch("target").fetch("representation")
    measurement = Primus::Analysis::SymbolStatistics.new(
      symbols: @observation.symbols(name), alphabet: @observation.alphabet(name),
      declaration_id: entry.fetch("id"), representation: name,
    ).to_result
    references = Primus::Analysis::ICReferencePacket.new.for_representation(name)
    snapshot = Primus::Analysis::ICInterpretation.new(
      measurement: measurement, references: references,
    ).to_h
    measurement.with_interpretation(snapshot)
  end

  def initial_data
    head, _status = Open3.capture2("git", "rev-parse", "HEAD")
    dirty, _status = Open3.capture2("git", "status", "--porcelain", "--", "lib", "bin")
    { "schema_version" => 1, "experiment_id" => @observation.experiment_id,
      "run_id" => @observation.run_id, "status" => "running",
      "started_at" => Time.now.utc.iso8601, "completed_at" => nil,
      "definition_sha256" => Digest::SHA256.hexdigest(@definition.bytes),
      "definition" => @definition.data,
      "git_head" => head.strip, "code_clean" => dirty.empty?,
      "ruby_version" => RUBY_VERSION, "results" => [], "errors" => [] }.
      merge(@observation.evidence)
  end
end
