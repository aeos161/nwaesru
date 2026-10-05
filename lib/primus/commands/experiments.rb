class Primus::Commands::Experiments < Primus::Commands::SubCommandBase
  desc "validate ID", "check a saved experiment without executing it"
  def validate(id)
    experiment = load_definition(id, definition_path(id))
    if experiment.valid?
      say "#{experiment.id}: valid"
      say "input SHA-256: #{experiment.source_digest}"
      if experiment.expectation["kind"] == "hash"
        show_hash_expectation(experiment.expectation,
                              experiment.output["policy"])
      else
        say "oracle SHA-256: #{experiment.expectation_digest}"
      end
    else
      raise Thor::Error, experiment.errors.map { |error|
        "#{error.attribute}: #{error.message}"
      }.join("; ")
    end
  rescue Primus::Experiment::LoadError => error
    raise Thor::Error, "definition load: #{error.message}"
  end

  desc "run ID", "execute and retain a saved experiment"
  map "run" => :execute
  option :output_path, type: :string, default: "experiments/runs"
  option :rerun, type: :boolean, default: false
  option :reason, type: :string
  def execute(id)
    path = definition_path(id)
    experiment = load_definition(id, path)
    runner = Primus::Experiment::Runner.new(experiment: experiment,
                                            output_path: options[:output_path])
    runner.run(rerun: options[:rerun], reason: options[:reason])
    entry = runner.log_entry
    say "#{entry.run_id}: #{entry.status} (#{entry.data["comparison"]})"
    unless entry.status == "matched"
      raise Thor::Error, entry.data["errors"].map { |item|
        item["message"]
      }.join("; ")
    end
  rescue Primus::Experiment::LoadError => error
    store = Primus::Experiment::Store.new(output_path: options[:output_path])
    store.failed_load(path: path, error: error)
    raise Thor::Error, "definition load: #{error.message}"
  rescue SystemCallError, ArgumentError,
         Primus::Experiment::Blake2b::Unavailable => error
    raise Thor::Error, "experiment run: #{error.message}"
  end

  desc "review ID [RUN_ID]", "show retained attempts"
  option :output_path, type: :string, default: "experiments/runs"
  def review(id, run_id = nil)
    validate_id!(id)
    store = Primus::Experiment::Store.new(output_path: options[:output_path])
    entries = store.review(id: id, run_id: run_id)
    show_planned(id) if Array(entries).empty?
    Array(entries).each { |entry| show_entry(id, entry) }
  rescue Primus::Experiment::Store::ReadError => error
    raise Thor::Error, "review: #{error.message}"
  rescue Primus::Experiment::LoadError => error
    raise Thor::Error, "definition load: #{error.message}"
  end

  private

  def validate_id!(id)
    return if /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/.match?(id)
    raise Thor::Error, "invalid experiment ID: #{id.inspect}"
  end

  def definition_path(id)
    validate_id!(id)
    "experiments/definitions/#{id}.yml"
  end

  def load_definition(id, path)
    experiment = Primus::Experiment.load(path: path)
    message = "#{path}: declared ID does not match #{id}"
    raise Primus::Experiment::LoadError, message unless experiment.id == id
    experiment
  end

  def show_planned(id)
    experiment = load_definition(id, definition_path(id))
    say "#{experiment.id}: planned — #{experiment.title}"
    say experiment.purpose
    expectation = experiment.expectation
    if expectation.is_a?(Hash) && expectation["kind"] == "hash"
      show_hash_expectation(expectation, experiment.output["policy"])
    end
  end

  def show_entry(id, entry)
    data = entry.data
    configuration = data["configuration"] || {}
    if configuration["title"]
      say "#{configuration["title"]}: #{configuration["purpose"]}"
    end
    say "#{id} #{entry.run_id}: #{entry.status} #{data["comparison"]}"
    say "Git HEAD: #{data["git_head"]} Ruby: #{data["runtime_version"]}"
    say "input: #{data["source_path"]}"
    say "input SHA-256: #{data["source_actual_sha256"]}"
    expectation = configuration["expectation"] || {}
    if expectation["kind"] == "hash"
      policy = configuration.fetch("output").fetch("policy")
      show_hash_expectation(expectation, policy)
      hash_check = data.dig("assessment", "hash_check")
      if hash_check
        label = digest_label(expectation)
        say "observed #{label}: #{hash_check["observed_digest"]}"
      end
      say "comparison: #{data["comparison"]}"
    else
      say "oracle: #{data["oracle_path"]}"
      say "oracle SHA-256: #{data["oracle_actual_sha256"]}"
    end
    prior = entry.previous_run_ids
    say "prior: #{prior.join(", ")}" if prior.any?
    data.fetch("errors", []).each { |error|
      say "#{error["stage"]}: #{error["message"]}"
    }
    show_artifacts(entry)
  end

  def show_hash_expectation(expectation, policy)
    say "hash algorithm: #{expectation["algorithm"]}"
    say "expected #{digest_label(expectation)}: #{expectation["digest"]}"
    say "output policy: #{policy}"
  end

  def digest_label(expectation)
    expectation.fetch("algorithm") == "sha512" ? "SHA-512" : "BLAKE2b-512"
  end

  def show_artifacts(entry)
    artifacts = entry.data.fetch("artifacts", {})
    artifacts.each { |name, artifact| say "#{name}: #{artifact["path"]}" }
    missing = artifacts.keys.reject { |name|
      File.file?(artifacts[name]["path"])
    }
    say "missing artifact: #{missing.join(", ")}" if missing.any?
  end
end
