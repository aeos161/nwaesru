class Primus::Commands::Experiments < Primus::Commands::SubCommandBase
  desc "validate DEFINITION", "check a saved experiment without executing it"
  def validate(path)
    experiment = Primus::Experiment.load(path: path)
    if experiment.valid?
      say "#{experiment.id}: valid"
      say "input SHA-256: #{experiment.source_digest}"
      say "oracle SHA-256: #{experiment.expectation_digest}"
    else
      raise Thor::Error, experiment.errors.map { |error|
        "#{error.attribute}: #{error.message}"
      }.join("; ")
    end
  rescue Primus::Experiment::LoadError => error
    raise Thor::Error, "definition load: #{error.message}"
  end

  desc "run DEFINITION", "execute and retain a saved experiment"
  map "run" => :execute
  option :output_path, type: :string, default: "experiments/runs"
  option :rerun, type: :boolean, default: false
  option :reason, type: :string
  def execute(path)
    experiment = Primus::Experiment.load(path: path)
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
  rescue SystemCallError, ArgumentError => error
    raise Thor::Error, "experiment run: #{error.message}"
  end

  desc "review ID [RUN_ID]", "show retained attempts"
  option :output_path, type: :string, default: "experiments/runs"
  def review(id, run_id = nil)
    store = Primus::Experiment::Store.new(output_path: options[:output_path])
    entries = store.review(id: id, run_id: run_id)
    show_planned(id) if Array(entries).empty?
    Array(entries).each { |entry| show_entry(id, entry) }
  rescue Primus::Experiment::Store::ReadError => error
    raise Thor::Error, "review: #{error.message}"
  end

  private

  def show_planned(id)
    path = "experiments/definitions/#{id}.yml"
    unless File.file?(path)
      raise Thor::Error, "#{id}: no saved definition or attempts"
    end
    experiment = Primus::Experiment.load(path: path)
    say "#{experiment.id}: planned — #{experiment.title}"
    say experiment.purpose
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
    say "oracle: #{data["oracle_path"]}"
    say "oracle SHA-256: #{data["oracle_actual_sha256"]}"
    prior = entry.previous_run_ids
    say "prior: #{prior.join(", ")}" if prior.any?
    data.fetch("errors", []).each { |error|
      say "#{error["stage"]}: #{error["message"]}"
    }
    show_artifacts(entry)
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
