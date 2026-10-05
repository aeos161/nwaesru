require "open3"

class Primus::Experiment::Runner
  CODE_PATHS = %w[lib bin Gemfile Gemfile.lock primus.gemspec
                  .tool-versions].freeze

  attr_reader :observation, :assessment, :log_entry

  def initialize(experiment:, output_path: "experiments/runs")
    @experiment = experiment
    @store = Primus::Experiment::Store.new(output_path: output_path)
    @output_path = output_path
  end

  def run(rerun: false, reason: nil)
    @observation = @assessment = @log_entry = nil
    if rerun && reason.to_s.strip.empty?
      raise ArgumentError,
            "rerun reason is required"
    end
    reject_output_overlap!
    valid = @experiment.valid?
    head = git_head
    clean = code_clean?
    valid &&= clean
    @hash_runtime = blake2b_runtime
    fingerprint = fingerprint_for(head)
    previous = @store.prior(id: @experiment.id, fingerprint: fingerprint)
    if previous && !rerun
      @log_entry = previous
      return nil
    end
    @store.snapshots(input_bytes: @experiment.input_bytes,
                     source_body: @experiment.source_body,
                     expected_bytes: @experiment.expected_bytes,
                     definition_bytes: @experiment.definition_bytes)
    @log_entry = @store.reserve(
      experiment: @experiment, fingerprint: fingerprint, git_head: head,
      code_clean: clean, hash_runtime: @hash_runtime,
      previous_run_ids: previous ? [previous.run_id] : [],
      rerun_reason: rerun ? reason : nil
    )
    if valid
      execute
    else
      @log_entry = @store.finish(
        @log_entry, status: "invalid", errors: @experiment.check_details
      )
    end
    nil
  rescue StandardError => error
    if @log_entry && @log_entry.status == "running"
      record_execution_error(error)
    end
    raise
  end

  private

  def execute
    @observation = produce_observation
    @assessment = Primus::Experiment::Evaluator.new.assess(
      observation: @observation, expectation: evaluation_expectation,
      policy: @experiment.output.fetch("policy")
    )
    status = @assessment.comparison == "match" ? "matched" : "mismatched"
    @log_entry = @store.finish(
      @log_entry, status: status, observation: @observation,
                  assessment: @assessment
    )
  end

  def evaluation_expectation
    if @experiment.expectation["kind"] == "hash"
      @experiment.expectation
    else
      @experiment.expected_bytes
    end
  end

  def produce_observation
    page = Primus::LiberPrimus::Page.new(
      number: @experiment.input.fetch("page_number"),
      data: @experiment.source_body.rstrip,
      source_body: @experiment.source_body,
      artifact_bytes: @experiment.input_bytes,
      source_path: @experiment.input_path,
    )
    builder = Primus::Document::Builder.new(pages: [page], strategy: :runic,
                                            track_delimiters: false)
    original = builder.build
    translated = original.accept(Primus::Document::Translator.new)
    derived = derive(translated)
    Primus::Experiment::Observation.new(
      output_bytes: derived.to_s(:letter),
      provenance: provenance_for(derived),
    )
  end

  def derive(translated)
    return translated if @experiment.operation == "runes_to_latin"

    parameters = @experiment.parameters
    primes = Prime.each.lazy.drop_while { |prime|
      prime < parameters.fetch("prime_start")
    }
    shift = Primus::Document::TotientShift.new(
      modulus: parameters.fetch("modulus"), key: primes,
    )
    shift.skip_sequence = parameters.fetch("skip_sequence")
    translated.accept(shift)
  end

  def provenance_for(document)
    document.tokens.select { |token|
      token.respond_to?(:index) && !token.index.nil? &&
        token.source_location&.rune_index
    }.each_with_index.map do |token, ordinal|
      source = token.source_location
      original_rune = @experiment.source_body.byteslice(
        source.byte_start...source.byte_end,
      )
      { "ordinal" => ordinal, "rune" => original_rune,
        "decoded_rune" => token.rune, "latin" => token.letter,
        **Primus::Transcription::SourceLocation::ATTRIBUTES.to_h do |name|
          [name.to_s, source.public_send(name)]
        end }
    end
  end

  def fingerprint_for(head)
    identity = { definition: @experiment.definition_data,
                 source_sha256: @experiment.source_digest,
                 oracle_sha256: @experiment.expectation_digest,
                 git_head: head, ruby_version: RUBY_VERSION, version: 1 }
    identity[:hash_runtime] = @hash_runtime if @hash_runtime
    Digest::SHA256.hexdigest(JSON.generate(sorted(identity)))
  end

  def blake2b_runtime
    return unless @experiment.id == "page-57-latin-blake2b512"

    Primus::Experiment::Blake2b.new.runtime
  end

  def sorted(value)
    case value
    when Hash then value.keys.sort.to_h { |key| [key, sorted(value[key])] }
    when Array then value.map { |item| sorted(item) }
    else value
    end
  end

  def git_head
    output, status = Open3.capture2("git", "rev-parse", "HEAD")
    raise "Cannot identify Git HEAD" unless status.success?
    output.strip
  end

  def code_clean?
    output, status = Open3.capture2("git", "status", "--porcelain",
                                    "--untracked-files=all", "--", *CODE_PATHS)
    return true if status.success? && output.empty?
    @experiment.errors.add(:base, "executable code differs from Git HEAD",
                           stage: "code", type: "DirtyCode")
    false
  end

  def reject_output_overlap!
    output = File.expand_path(@output_path)
    [@experiment.input_path,
     @experiment.expectation_path].compact.each do |path|
      source = File.expand_path(path)
      if source.start_with?("#{output}/") || output == source
        raise ArgumentError,
              "output path overlaps research input"
      end
    end
  end

  def record_execution_error(error)
    failure = { "stage" => "execution", "type" => error.class.name,
                "message" => error.message }
    @log_entry = @store.finish(
      @log_entry, status: "error", errors: [failure],
                  observation: @observation, assessment: @assessment
    )
  end
end
