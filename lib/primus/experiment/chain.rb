class Primus::Experiment::Chain
  attr_reader :observation, :checkpoints, :failed_step

  def initialize(steps:, transcription:, publisher:)
    @steps = steps
    @transcription = transcription
    @publisher = publisher
    @checkpoints = []
  end

  def run
    capture({ "id" => "original", "operation" => "capture", "parameters" => {} },
            original_bytes)
    @steps.each_with_index { |step, index| execute(step, index + 1) }
    nil
  end

  private

  def original_bytes
    @transcription.pages.map(&:source_body).join
  end

  def execute(step, index)
    if step.fetch("operation") == "latin"
      latin = Primus::Experiment::Latin.new
      @observation = latin.call(@transcription)
      capture(step, @observation.output_bytes, rendering: latin.output_map)
    else
      operations = { "totient" => Primus::Experiment::Totient,
                     "atbash" => Primus::Experiment::Atbash,
                     "reverse-runes" => Primus::Experiment::RuneReversal }
      @transcription = operations.fetch(step.fetch("operation")).new(step.fetch("parameters")).call(@transcription)
      capture(step, @transcription.tokens.map(&:lexeme).join)
    end
  rescue StandardError => error
    @failed_step = { "id" => step.fetch("id"), "index" => index,
                     "status" => "error", "type" => error.class.name,
                     "message" => error.message }
    raise
  end

  def capture(step, bytes, rendering: nil)
    checkpoint = Primus::Experiment::Checkpoint.new(
      step: step, ordinal: @checkpoints.size, transcription: @transcription,
      output_bytes: bytes, parent_id: @checkpoints.last&.id, rendering: rendering
    )
    @publisher.call(checkpoint)
    @checkpoints << checkpoint
  end
end
