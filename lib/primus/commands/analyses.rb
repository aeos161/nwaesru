require "shellwords"

class Primus::Commands::Analyses < Primus::Commands::SubCommandBase
  desc "run EXPERIMENT_ID RUN_ID", "analyze a saved checkpoint"
  map "run" => :execute
  option :definition, type: :string, required: true
  option :output_path, type: :string, default: "experiments/runs"
  def execute(experiment_id, run_id = nil)
    raise Thor::Error, "explicit run ID is required" unless run_id
    definition = Primus::Analysis::Definition.new(path: options[:definition])
    observation = Primus::Analysis::ObservationReader.new(
      output_path: options[:output_path], experiment_id: experiment_id, run_id: run_id,
      stage: definition.stage,
    ).to_observation
    runner = Primus::Analysis::Runner.new(definition: definition,
                                          observation: observation)
    runner.run
    show(runner.log_entry)
    say "review: #{Shellwords.join(['bin/primus', 'analyses', 'review', experiment_id,
                                    run_id, runner.log_entry.analysis_run_id,
                                    '--output-path', options[:output_path]])}"
  rescue Primus::Analysis::Definition::Error, Primus::Analysis::ObservationReader::Error,
         Primus::Analysis::Store::Error => error
    raise Thor::Error, "analysis run: #{error.message}"
  end

  desc "review EXPERIMENT_ID RUN_ID [ANALYSIS_RUN_ID]", "review retained measurements"
  option :output_path, type: :string, default: "experiments/runs"
  def review(experiment_id, run_id, analysis_run_id = nil)
    validate_identity!(experiment_id, run_id, analysis_run_id)
    directory = File.realpath(File.join(options[:output_path], experiment_id, run_id))
    root = File.realpath(options[:output_path])
    raise Thor::Error, "selected run escapes output root" unless directory.start_with?("#{root}/")
    store = Primus::Analysis::Store.new(directory: directory)
    store.review(analysis_run_id).each do |entry|
      unless entry.matches_observation?(experiment_id: experiment_id, run_id: run_id)
        raise Thor::Error, "analysis observation identity mismatch"
      end
      show(entry)
    end
  rescue Primus::Analysis::Store::Error, Errno::ENOENT, Errno::ENOTDIR => error
    raise Thor::Error, "analysis review: #{error.message}"
  end

  private

  def validate_identity!(experiment_id, run_id, analysis_run_id)
    unless Primus::Analysis::ID.match?(experiment_id) &&
        Primus::Analysis::RUN_ID.match?(run_id)
      raise Thor::Error, "invalid observation identity"
    end
    if analysis_run_id && !Primus::Analysis::RUN_ID.match?(analysis_run_id)
      raise Thor::Error, "invalid analysis run ID"
    end
  end

  def show(entry)
    say "experiment ID: #{entry.experiment_id} run ID: #{entry.run_id} analysis ID: #{entry.analysis_run_id}"
    say "status: #{entry.status}"
    say "saved output SHA-256: #{entry.output_sha256} provenance SHA-256: #{entry.provenance_sha256}"
    checkpoint = entry.checkpoint
    if checkpoint
      say "checkpoint: #{checkpoint['requested_stage']} resolved #{checkpoint['step_id']} #{checkpoint['id']}"
      say "checkpoint output SHA-256: #{checkpoint.dig('output', 'sha256')} symbols SHA-256: #{checkpoint.dig('symbols', 'sha256')}"
    end
    say "definition SHA-256: #{entry.definition_sha256} code: #{entry.git_head} Ruby: #{entry.ruby_version}"
    say "started: #{entry.started_at} completed: #{entry.completed_at}"
    entry.measurements.each { |measurement| show_result(measurement, checkpoint) }
  end

  def show_result(result, checkpoint)
    stage = checkpoint ? checkpoint.fetch("requested_stage") : "final"
    say "#{result.declaration_id} #{stage} #{result.representation} alphabet size #{result.alphabet_size} sample size #{result.sample_size} distinct #{result.distinct_count}"
    result.frequencies.each do |bin|
      say "#{bin.fetch('index')} #{bin.fetch('symbol')} #{bin.fetch('count')} #{bin.fetch('relative_frequency').inspect}"
    end
    ic = result.ic
    say "raw IC: #{ic.fetch('status')} #{ic.fetch('numerator')}/#{ic.fetch('denominator')} #{ic.fetch('value').inspect}"
    show_interpretation(result)
  end

  def show_interpretation(result)
    snapshot = result.interpretation
    unless snapshot
      say "English comparison: insufficient evidence — this historical analysis did not retain an interpretation; create a new analysis for a versioned comparison."
      return
    end
    say "#{snapshot.fetch('text')} (N=#{snapshot.fetch('sample_size')})"
    snapshot.fetch("references").each do |reference|
      difference = snapshot.fetch("differences")[reference.fetch("id")]
      next unless difference
      say "#{reference.fetch('id')}: #{reference.fetch('numerator')}/#{reference.fetch('denominator')} (N=#{reference.fetch('sample_size')}); signed difference #{difference.fetch('numerator')}/#{difference.fetch('denominator')}"
    end
    uniform = snapshot["theoretical_uniform"]
    say "Theoretical uniform benchmark: #{uniform.fetch('numerator')}/#{uniform.fetch('denominator')}" if uniform
    say snapshot.fetch("repetition_note")
    say snapshot.fetch("limitations") if snapshot["limitations"]
  end
end
