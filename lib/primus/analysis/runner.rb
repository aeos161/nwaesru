require "open3"

class Primus::Analysis::Runner
  attr_reader :record

  def initialize(definition:, observation:)
    @definition, @observation = definition, observation
    @store = Primus::Analysis::Store.new(directory: observation.directory)
  end

  def run
    results = @definition.declarations.map { |entry| result_for(entry) }
    data = initial_data
    id = @store.reserve(data, @definition.bytes)
    data.merge!("status" => "completed", "completed_at" => Time.now.utc.iso8601,
                "results" => results)
    @store.finish(id, data)
    @record = data
    nil
  rescue StandardError => error
    record_error(id, data, error) if id
    raise
  end

  private

  def result_for(entry)
    name = entry.fetch("target").fetch("representation")
    profile = @observation.profiles.fetch(name)
    result = Primus::Analysis::SymbolStatistics.new(
      symbols: @observation.symbols(name), alphabet: profile.fetch("alphabet"),
      declaration_id: entry.fetch("id"), representation: name,
    ).to_result
    { "declaration_id" => entry.fetch("id"), "analyzer" => "symbol-statistics",
      "version" => 1, "stage" => "final", "representation" => name,
      "profile" => profile, "exclusions" => "non-GP passthrough literals",
      "result" => result.to_h }
  end

  def initial_data
    head, _status = Open3.capture2("git", "rev-parse", "HEAD")
    dirty, _status = Open3.capture2("git", "status", "--porcelain", "--", "lib", "bin")
    { "schema_version" => 1, "experiment_id" => @observation.experiment_id,
      "run_id" => @observation.run_id, "status" => "running",
      "started_at" => Time.now.utc.iso8601, "completed_at" => nil,
      "definition_sha256" => Digest::SHA256.hexdigest(@definition.bytes),
      "definition" => @definition.data,
      "observation_record_sha256" => Digest::SHA256.hexdigest(@observation.record_bytes),
      "observation_output" => @observation.record.dig("artifacts", "output.txt"),
      "observation_provenance" => @observation.record.dig("artifacts", "provenance.json"),
      "representations" => @observation.profiles,
      "output_policy" => @observation.record.dig("configuration", "output", "policy"),
      "git_head" => head.strip, "code_clean" => dirty.empty?,
      "ruby_version" => RUBY_VERSION, "results" => [], "errors" => [] }
  end

  def record_error(id, data, error)
    data.merge!("status" => "error", "completed_at" => Time.now.utc.iso8601,
                "errors" => [{ "type" => error.class.name, "message" => error.message }])
    @store.finish(id, data)
  end
end
