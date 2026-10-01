class Primus::Experiment::Observation
  attr_reader :output_bytes, :provenance

  def initialize(output_bytes:, provenance: [])
    @output_bytes = output_bytes.dup.freeze
    @provenance = provenance.freeze
  end
end
