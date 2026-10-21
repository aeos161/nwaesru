class Primus::Analysis::Observation
  attr_reader :experiment_id, :run_id, :directory, :evidence

  def initialize(experiment_id:, run_id:, directory:, symbols_by_representation:,
                 profiles:, evidence:)
    @experiment_id = experiment_id.dup.freeze
    @run_id = run_id.dup.freeze
    @directory = directory.dup.freeze
    @symbols_by_representation = owned(symbols_by_representation)
    @profiles = owned(profiles)
    @evidence = owned(evidence)
  end

  def symbols(representation)
    @symbols_by_representation.fetch(representation)
  end

  def alphabet(representation)
    profile(representation).fetch("alphabet")
  end

  def profile(representation)
    @profiles.fetch(representation)
  end

  def checkpoint
    @evidence.fetch("checkpoint")
  end

  private

  def owned(value)
    case value
    when Hash then value.each_with_object({}) { |(key, item), copy| copy[owned(key)] = owned(item) }.freeze
    when Array then value.map { |item| owned(item) }.freeze
    else value.dup.freeze
    end
  end
end
