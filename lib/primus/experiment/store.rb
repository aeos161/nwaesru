require "fileutils"
require "json"
require "securerandom"
require "time"

class Primus::Experiment::Store
  class ReadError < StandardError; end

  attr_reader :output_path

  def initialize(output_path: "experiments/runs")
    @output_path = output_path
  end

  def attempts(id:)
    paths = Dir.glob(File.join(output_path, id, "*", "record.json"))
    paths.map { |path| read_record(path) }
  end

  def prior(id:, fingerprint:)
    attempts(id: id).reverse.detect do |entry|
      entry.data["execution_fingerprint"] == fingerprint
    end
  end

  def review(id:, run_id: nil)
    entries = attempts(id: id)
    return entries if run_id.nil?
    entry = entries.detect { |attempt| attempt.run_id == run_id }
    raise ReadError, "#{id}/#{run_id}: saved attempt not found" unless entry
    entry
  end

  def reserve(experiment:, fingerprint:, git_head:, code_clean:,
              previous_run_ids: [],
              rerun_reason: nil)
    id = experiment.id.to_s.empty? ? "failed-load" : experiment.id
    run_id = "#{Time.now.utc.strftime("%Y%m%dT%H%M%S")}-#{SecureRandom.hex(6)}"
    directory = File.join(output_path, id, run_id)
    FileUtils.mkdir_p(directory)
    data = initial_data(experiment, run_id, fingerprint, git_head,
                        code_clean, previous_run_ids, rerun_reason)
    entry = Primus::Experiment::LogEntry.new(data: data)
    save(entry, directory: directory)
    entry
  end

  def finish(entry, status:, errors: [], observation: nil, assessment: nil)
    entry.data["status"] = status
    entry.data["completed_at"] = Time.now.utc.iso8601
    entry.data["errors"] = errors
    entry.data["comparison"] =
      assessment ? assessment.comparison : "not_checked"
    entry.data["observation"] =
      observation && { "output_bytes" => observation.output_bytes.bytesize }
    entry.data["assessment"] = assessment&.to_h
    directory = record_directory(entry)
    save(entry, directory: directory, observation: observation)
    Primus::Experiment::LogEntry.new(data: entry.data,
                                     observation: observation,
                                     assessment: assessment)
  end

  def failed_load(path:, error:)
    run_id = "#{Time.now.utc.strftime("%Y%m%dT%H%M%S")}-#{SecureRandom.hex(6)}"
    directory = File.join(output_path, "failed-load", run_id)
    FileUtils.mkdir_p(directory)
    data = { "schema_version" => 1, "run_id" => run_id,
             "experiment_id" => nil, "status" => "invalid",
             "comparison" => "not_checked", "observation" => nil,
             "assessment" => nil, "errors" => [{ "stage" => "definition",
                                                 "type" => error.class.name,
                                                 "message" => error.message }],
             "artifacts" => {}, "definition_path" => path }
    if File.file?(path)
      snapshot(data, directory, "definition.yml",
               File.binread(path))
    end
    save(Primus::Experiment::LogEntry.new(data: data), directory: directory)
  end

  private

  def initial_data(experiment, run_id, fingerprint, git_head, clean, previous,
                   reason)
    { "schema_version" => 1, "run_id" => run_id,
      "experiment_id" => experiment.id, "action" => "run",
      "started_at" => Time.now.utc.iso8601, "completed_at" => nil,
      "status" => "running", "comparison" => "not_checked",
      "definition_sha256" => Digest::SHA256.hexdigest(experiment.definition_bytes),
      "definition_path" => experiment.definition_path,
      "configuration" => experiment.definition_data,
      "source_path" => experiment.input_path,
      "source_declared_sha256" => if experiment.input.is_a?(Hash)
                                    experiment.input["sha256"]
                                  end,
      "source_actual_sha256" => experiment.source_digest,
      "oracle_path" => experiment.expectation_path,
      "oracle_declared_sha256" => if experiment.expectation.is_a?(Hash)
                                    experiment.expectation["sha256"]
                                  end,
      "oracle_actual_sha256" => experiment.expectation_digest,
      "runtime_version" => RUBY_VERSION, "git_head" => git_head,
      "code_clean" => clean, "execution_fingerprint" => fingerprint,
      "previous_run_ids" => previous, "rerun_reason" => reason,
      "checks" => experiment.check_details,
      "errors" => [], "observation" => nil, "assessment" => nil,
      "artifacts" => {} }
  end

  def record_directory(entry)
    File.join(output_path, entry.data["experiment_id"], entry.run_id)
  end

  def save(entry, directory:, observation: nil)
    data = entry.data
    config = data["configuration"]
    if config
      if @definition_bytes
        snapshot(data, directory, "definition.yml",
                 @definition_bytes)
      end
      snapshot(data, directory, "input.yml", @input_bytes) if @input_bytes
      snapshot(data, directory, "source-body.txt", @source_body) if @source_body
      if @expected_bytes
        snapshot(data, directory, "expected.txt",
                 @expected_bytes)
      end
    end
    if observation
      snapshot(data, directory, "output.txt", observation.output_bytes)
      snapshot(data, directory, "provenance.json",
               JSON.pretty_generate(observation.provenance))
    end
    atomic_record(directory, data)
  end

  def snapshot(data, directory, name, bytes)
    path = File.expand_path(File.join(directory, name))
    File.binwrite(path, bytes)
    data["artifacts"][name] = { "path" => path, "bytes" => bytes.bytesize,
                                "sha256" => Digest::SHA256.hexdigest(bytes) }
  end

  def atomic_record(directory, data)
    temporary = File.join(directory, ".record-#{SecureRandom.hex(4)}")
    File.binwrite(temporary, JSON.pretty_generate(data))
    File.rename(temporary, File.join(directory, "record.json"))
  end

  def read_record(path)
    data = JSON.parse(File.binread(path))
    assessment = data["assessment"] &&
      Primus::Experiment::Assessment.new(
        **data["assessment"].transform_keys(&:to_sym),
      )
    Primus::Experiment::LogEntry.new(data: data,
                                     observation: saved_observation(data),
                                     assessment: assessment)
  rescue JSON::ParserError, SystemCallError => error
    raise ReadError, "#{path}: #{error.class}: #{error.message}"
  end

  def saved_observation(data)
    return unless data["observation"]
    artifacts = data.fetch("artifacts")
    output = artifacts.fetch("output.txt", {})["path"]
    return unless output && File.file?(output)
    provenance = artifacts.fetch("provenance.json", {})["path"]
    symbols = if provenance && File.file?(provenance)
                JSON.parse(File.binread(provenance))
              else
                []
              end
    Primus::Experiment::Observation.new(
      output_bytes: File.binread(output).force_encoding(Encoding::UTF_8),
      provenance: symbols,
    )
  end

  public

  def snapshots(input_bytes:, source_body:, expected_bytes:, definition_bytes:)
    @input_bytes = input_bytes
    @source_body = source_body
    @expected_bytes = expected_bytes
    @definition_bytes = definition_bytes
  end
end
