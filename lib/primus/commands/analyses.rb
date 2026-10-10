class Primus::Commands::Analyses < Primus::Commands::SubCommandBase
  desc "run EXPERIMENT_ID RUN_ID", "analyze a saved final output"
  map "run" => :execute
  option :definition, type: :string, required: true
  option :output_path, type: :string, default: "experiments/runs"
  def execute(experiment_id, run_id = nil)
    raise Thor::Error, "explicit run ID is required" unless run_id
    definition = Primus::Analysis::Definition.new(path: options[:definition])
    observation = Primus::Analysis::SavedObservation.new(
      output_path: options[:output_path], experiment_id: experiment_id, run_id: run_id,
    )
    runner = Primus::Analysis::Runner.new(definition: definition,
                                          observation: observation)
    runner.run
    show(runner.record)
    say "review: bin/primus analyses review #{experiment_id} #{run_id} #{runner.record.fetch('analysis_run_id')} --output-path #{options[:output_path]}"
  rescue Primus::Analysis::Definition::Error, Primus::Analysis::SavedObservation::Error,
         Primus::Analysis::Store::Error => error
    raise Thor::Error, "analysis run: #{error.message}"
  end

  desc "review EXPERIMENT_ID RUN_ID [ANALYSIS_RUN_ID]", "review retained measurements"
  option :output_path, type: :string, default: "experiments/runs"
  def review(experiment_id, run_id, analysis_run_id = nil)
    validate_identity!(experiment_id, run_id, analysis_run_id)
    directory = File.realpath(File.join(options[:output_path], experiment_id, run_id))
    store = Primus::Analysis::Store.new(directory: directory)
    store.review(analysis_run_id).each do |record|
      raise Thor::Error, "analysis observation identity mismatch" unless record.values_at("experiment_id", "run_id") == [experiment_id, run_id]
      show(record)
    end
  rescue Primus::Analysis::Store::Error, Errno::ENOENT, Errno::ENOTDIR => error
    raise Thor::Error, "analysis review: #{error.message}"
  end

  private

  def validate_identity!(experiment_id, run_id, analysis_run_id)
    unless Primus::Analysis::SavedObservation::ID.match?(experiment_id) &&
        Primus::Analysis::SavedObservation::RUN_ID.match?(run_id)
      raise Thor::Error, "invalid observation identity"
    end
    if analysis_run_id && !Primus::Analysis::SavedObservation::RUN_ID.match?(analysis_run_id)
      raise Thor::Error, "invalid analysis run ID"
    end
  end

  def show(record)
    say "experiment ID: #{record.fetch('experiment_id')} run ID: #{record.fetch('run_id')} analysis ID: #{record.fetch('analysis_run_id')}"
    say "status: #{record.fetch('status')}"
    record.fetch("results").each { |entry| show_result(entry) }
  end

  def show_result(entry)
    result = entry.fetch("result")
    say "#{entry.fetch('declaration_id')} final #{entry.fetch('representation')} alphabet size #{result.fetch('alphabet_size')} sample size #{result.fetch('sample_size')} distinct #{result.fetch('distinct_count')}"
    result.fetch("frequencies").each do |bin|
      say "#{bin.fetch('index')} #{bin.fetch('symbol')} #{bin.fetch('count')} #{bin.fetch('relative_frequency').inspect}"
    end
    ic = result.fetch("ic")
    say "raw IC: #{ic.fetch('status')} #{ic.fetch('numerator')}/#{ic.fetch('denominator')} #{ic.fetch('value').inspect}"
  end
end
