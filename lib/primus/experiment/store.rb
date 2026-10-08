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
              hash_runtime: nil,
              previous_run_ids: [],
              rerun_reason: nil)
    id = experiment.id.to_s.empty? ? "failed-load" : experiment.id
    run_id = "#{Time.now.utc.strftime("%Y%m%dT%H%M%S")}-#{SecureRandom.hex(6)}"
    directory = File.join(output_path, id, run_id)
    FileUtils.mkdir_p(directory)
    data = initial_data(experiment, run_id, fingerprint, git_head,
                        code_clean, previous_run_ids, rerun_reason)
    data["hash_runtime"] = hash_runtime if hash_runtime
    if experiment.v2? && experiment.checks.is_a?(Array) && experiment.checks.size > 1
      data.merge!("comparison" => "not_applicable", "assessment_records" => [],
                  "completion_summary" => { "match" => 0, "mismatch" => 0, "error" => 0 },
                  "matching_outcome" => nil)
      data.delete("assessment")
    end
    entry = Primus::Experiment::LogEntry.new(data: data)
    save(entry, directory: directory)
    entry
  end

  def finish(entry, status:, errors: [], observation: nil, assessment: nil)
    entry.data["status"] = status
    entry.data["completed_at"] = Time.now.utc.iso8601
    entry.data["errors"] = errors
    entry.data["comparison"] = if entry.data.key?("assessment_records")
                                 "not_applicable"
                               else
                                 assessment ? assessment.comparison : "not_checked"
                               end
    entry.data["observation"] =
      observation && { "output_bytes" => observation.output_bytes.bytesize }
    entry.data["assessment"] = assessment&.to_h unless entry.data.key?("assessment_records")
    directory = record_directory(entry)
    save(entry, directory: directory, observation: observation)
    Primus::Experiment::LogEntry.new(data: entry.data,
                                     observation: observation,
                                     assessment: assessment)
  end

  def record_observation(entry, observation)
    entry.data["observation"] = { "output_bytes" => observation.output_bytes.bytesize }
    save(entry, directory: record_directory(entry), observation: observation)
  end

  def reserve_assessment(entry, check, policy)
    id = "#{Time.now.utc.strftime('%Y%m%dT%H%M%S')}-#{SecureRandom.hex(6)}"
    reference = "assessments/#{id}/record.json"
    data = { "schema_version" => 2, "assessment_id" => id,
             "check_id" => check.fetch("id"), "check" => check,
             "observation" => { "experiment_id" => entry.data.fetch("experiment_id"),
                                "run_id" => entry.run_id },
             "policy" => policy, "started_at" => Time.now.utc.iso8601,
             "completed_at" => nil, "status" => "running",
             "comparison" => "not_checked", "errors" => [], "artifacts" => {},
             "runtime_version" => RUBY_VERSION,
             "assessment_code" => entry.data.fetch("git_head") }
    directory = File.dirname(File.join(record_directory(entry), reference))
    FileUtils.mkdir_p(directory)
    atomic_record(directory, data)
    entry.data.fetch("assessment_records") << reference
    atomic_record(record_directory(entry), entry.data)
    data
  end

  def record_expected(entry, data, bytes)
    directory = File.join(record_directory(entry), "assessments", data.fetch("assessment_id"))
    snapshot(data, directory, "expected.txt", bytes)
    atomic_record(directory, data)
  end

  def finish_assessment(entry, data)
    directory = File.join(record_directory(entry), "assessments", data.fetch("assessment_id"))
    atomic_record(directory, data)
    counts = entry.data.fetch("completion_summary")
    counts[data.fetch("status")] += 1
    entry.data["matching_outcome"] = "matched" if counts["match"].positive?
    atomic_record(record_directory(entry), entry.data)
  end

  def finish_collection(entry, assessments)
    counts = { "match" => 0, "mismatch" => 0, "error" => 0 }
    assessments.each { |item| counts[item["status"]] += 1 }
    entry.data["completion_summary"] = counts
    entry.data["matching_outcome"] = counts["match"].positive? ? "matched" : "no_match"
    entry.data["status"] = counts["error"].positive? ? "error" : "completed"
    entry.data["completed_at"] = Time.now.utc.iso8601
    atomic_record(record_directory(entry), entry.data)
    Primus::Experiment::LogEntry.new(data: entry.data, assessments: assessments,
                                     observation: saved_observation(entry.data))
  end

  def finish_collection_error(entry)
    atomic_record(record_directory(entry), entry.data)
    Primus::Experiment::LogEntry.new(data: entry.data)
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
    return v2_initial_data(experiment, run_id, fingerprint, git_head, clean, previous, reason) if experiment.v2?
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
      "oracle_actual_sha256" => experiment.checks.is_a?(Array) && experiment.checks.size > 1 ? nil : experiment.expectation_digest,
      "runtime_version" => RUBY_VERSION, "git_head" => git_head,
      "code_clean" => clean, "execution_fingerprint" => fingerprint,
      "previous_run_ids" => previous, "rerun_reason" => reason,
      "checks" => experiment.check_details,
      "errors" => [], "observation" => nil, "assessment" => nil,
      "artifacts" => {} }
  end

  def v2_initial_data(experiment, run_id, identity, head, clean, previous,
                      reason)
    oracle = experiment.checks.first["expectation"] if experiment.checks.is_a?(Array) && experiment.checks.size == 1 && experiment.checks.first.is_a?(Hash)
    source_checksum = experiment.input["sha256"] if experiment.input.is_a?(Hash)
    oracle_checksum = oracle["sha256"] if oracle.is_a?(Hash)
    { "schema_version" => 2, "run_id" => run_id,
      "experiment_id" => experiment.id, "action" => "run",
      "started_at" => Time.now.utc.iso8601, "completed_at" => nil,
      "status" => "running", "comparison" => "not_checked",
      "definition_sha256" => Digest::SHA256.hexdigest(experiment.definition_bytes),
      "definition_path" => experiment.definition_path,
      "configuration" => experiment.definition_data,
      "source_path" => experiment.input_path,
      "source_declared_sha256" => source_checksum,
      "source_actual_sha256" => experiment.source_digest,
      "oracle_path" => experiment.checks.is_a?(Array) && experiment.checks.size > 1 ? nil : experiment.expectation_path,
      "oracle_declared_sha256" => oracle_checksum,
      "oracle_actual_sha256" => experiment.expectation_digest,
      "runtime_version" => RUBY_VERSION, "git_head" => head,
      "code_clean" => clean, "execution_identity" => identity,
      "previous_run_ids" => previous, "rerun_reason" => reason,
      "checks" => experiment.check_details, "errors" => [],
      "observation" => nil, "assessment" => nil, "artifacts" => {} }
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
    if observation && !data.fetch("artifacts").key?("output.txt")
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
    assessment = if data["assessment"]
                   attributes = data["assessment"].dup
                   hash_check = attributes.delete("hash_check")
                   Primus::Experiment::Assessment.new(
                     **attributes.transform_keys(&:to_sym),
                   ).tap do |item|
                     item.restore_hash_check(hash_check) if hash_check
                   end
                 end
    assessments = read_assessments(path, data) if data.key?("assessment_records")
    Primus::Experiment::LogEntry.new(data: data,
                                     observation: saved_observation(data),
                                     assessment: assessment,
                                     assessments: assessments)
  rescue JSON::ParserError, SystemCallError => error
    raise ReadError, "#{path}: #{error.class}: #{error.message}"
  end

  def read_assessments(path, data)
    run_directory = File.dirname(path)
    references = data.fetch("assessment_records")
    unless references.is_a?(Array) && references.uniq == references
      raise ReadError, "#{path}: invalid assessment references"
    end
    references.map do |reference|
      unless reference.is_a?(String) && reference.match?(%r{\Aassessments/[^/]+/record\.json\z})
        raise ReadError, "#{path}: invalid assessment reference"
      end
      assessment_path = File.join(run_directory, reference)
      unless File.realpath(assessment_path).start_with?("#{File.realpath(run_directory)}/")
        raise ReadError, "#{path}: assessment reference escapes run directory"
      end
      item = JSON.parse(File.binread(assessment_path))
      raise ReadError, "#{assessment_path}: invalid assessment record" unless item.is_a?(Hash)
      raise ReadError, "#{assessment_path}: unsupported schema" unless item["schema_version"] == 2
      unless item["observation"].is_a?(Hash) && item["check"].is_a?(Hash) &&
          item["check_id"] == item["check"]["id"] &&
          %w[running match mismatch error].include?(item["status"])
        raise ReadError, "#{assessment_path}: invalid assessment evidence"
      end
      unless item["assessment_id"] == File.basename(File.dirname(assessment_path)) &&
          item.dig("observation", "experiment_id") == data["experiment_id"] &&
          item.dig("observation", "run_id") == data["run_id"]
        raise ReadError, "#{assessment_path}: invalid observation reference"
      end
      item
    end
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
