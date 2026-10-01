class Primus::Experiment::LogEntry
  attr_reader :data, :observation, :assessment

  def initialize(data:, observation: nil, assessment: nil)
    @data = data
    @observation = observation
    @assessment = assessment
  end

  def run_id
    data["run_id"]
  end

  def status
    data["status"]
  end

  def previous_run_ids
    data["previous_run_ids"] || []
  end

  def rerun_reason
    data["rerun_reason"]
  end
end
