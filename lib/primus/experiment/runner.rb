require "open3"

class Primus::Experiment::Runner
  CODE_PATHS = %w[lib bin Gemfile Gemfile.lock primus.gemspec
                  .tool-versions].freeze
  BLAKE512_IDENTITY_KEYS = %w[backend available schema_version algorithm
                              gem_version upstream_revision source_sha256
                              native_sha256 ruby_engine ruby_api_version
                              ruby_platform dlext].freeze

  attr_reader :observation, :assessment, :assessments, :log_entry

  def initialize(experiment:, output_path: "experiments/runs")
    @experiment = experiment
    @store = Primus::Experiment::Store.new(output_path: output_path)
    @output_path = output_path
  end

  def run(rerun: false, reason: nil)
    return run_v2(rerun: rerun, reason: reason) if @experiment.v2?
    @observation = @assessment = @log_entry = nil
    @assessments = nil
    if rerun && reason.to_s.strip.empty?
      raise ArgumentError,
            "rerun reason is required"
    end
    reject_output_overlap!
    valid = @experiment.valid?
    head = git_head
    clean = code_clean?
    valid &&= clean
    @hash_runtime = hash_runtime
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

  def run_v2(rerun:, reason:)
    @observation = @assessment = @log_entry = nil
    @assessments = nil
    @hash_runtime = nil
    raise ArgumentError, "rerun reason is required" if rerun && reason.to_s.strip.empty?
    reject_output_overlap!
    valid = @experiment.valid?
    head = git_head
    clean = code_clean?
    valid &&= clean
    @hash_runtime = hash_runtime unless @experiment.checks.is_a?(Array) && @experiment.checks.size > 1
    @store.snapshots(input_bytes: @experiment.input_bytes,
                     source_body: @experiment.source_body,
                     expected_bytes: @experiment.checks.size > 1 ? nil : @experiment.expected_bytes,
                     definition_bytes: @experiment.definition_bytes)
    @log_entry = @store.reserve(
      experiment: @experiment, fingerprint: v2_identity(head), git_head: head,
      code_clean: clean, hash_runtime: @hash_runtime,
      rerun_reason: rerun ? reason : nil
    )
    if valid
      @experiment.checks.size > 1 ? execute_collection : execute
    else
      @log_entry = @store.finish(@log_entry, status: "invalid",
                                errors: @experiment.check_details)
    end
    nil
  rescue StandardError => error
    record_execution_error(error) if @log_entry && @log_entry.status == "running"
    raise
  end

  def v2_identity(head)
    identity = { source_sha256: @experiment.source_digest,
                 input_selection: @experiment.input_path,
                 recipe: @experiment.recipe, output: @experiment.output,
                 git_head: head, ruby_version: RUBY_VERSION, version: 2 }
    Digest::SHA256.hexdigest(JSON.generate(sorted(identity)))
  end

  def execute
    @observation = produce_observation
    @store.record_observation(@log_entry, @observation) if @experiment.v2?
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

  def execute_collection
    @observation = produce_observation
    @store.record_observation(@log_entry, @observation)
    @assessments = @experiment.checks.map { |check| assess_check(check) }
    @log_entry = @store.finish_collection(@log_entry, @assessments)
  end

  def assess_check(check)
    data = @store.reserve_assessment(@log_entry, check, @experiment.output.fetch("policy"))
    if check["strategy"] == "plaintext"
      @store.record_expected(@log_entry, data, @experiment.expected_bytes_by_check.fetch(check.fetch("id")))
    end
    begin
      data["backend"] = check_runtime(check)
      unavailable_backend!(check, data["backend"]) if data["backend"]["available"] == false
      assessment = Primus::Experiment::Evaluator.new.assess(
        observation: @observation, expectation: check_expectation(check),
        policy: @experiment.output.fetch("policy")
      )
      data.merge!("status" => assessment.comparison,
                  "comparison" => assessment.comparison,
                  "detail" => assessment.to_h)
    rescue StandardError => error
      data.merge!("status" => "error", "comparison" => "not_checked",
                  "errors" => [{ "stage" => "assessment", "type" => error.class.name,
                                 "message" => error.message }])
      data["backend"] ||= { "available" => false }
      data["backend"]["error_class"] ||= error.class.name unless data["backend"]["available"]
    ensure
      data["completed_at"] = Time.now.utc.iso8601
      data["output_sha256"] = @log_entry.data.dig("artifacts", "output.txt", "sha256")
      data["expected_length"] = check["strategy"] == "hash" ? 64 : @experiment.expected_bytes_by_check.fetch(check.fetch("id")).bytesize
      data["expected_provenance"] = check.dig("expectation", "provenance")
      data["assessment_identity"] = assessment_identity(data)
      @store.finish_assessment(@log_entry, data)
    end
    data
  end

  def check_expectation(check)
    if check["strategy"] == "hash"
      check.fetch("expectation").merge("algorithm" => check.fetch("algorithm"))
    else
      @experiment.expected_bytes_by_check.fetch(check.fetch("id"))
    end
  end

  def check_runtime(check)
    case check["algorithm"]
    when "blake2b512" then Primus::Experiment::Blake2b.new.runtime.merge("backend" => "openssl-blake2b512")
    when "blake512" then Primus::Experiment::Blake512.new.runtime
    else { "backend" => check["strategy"] == "plaintext" ? "ruby-bytes" : "ruby-digest-sha512",
           "available" => true, "ruby_version" => RUBY_VERSION }
    end
  end

  def unavailable_backend!(check, descriptor)
    message = descriptor["error_message"] || "#{check['algorithm']} backend unavailable"
    klass = check["algorithm"] == "blake512" ? Primus::Experiment::Blake512::Unavailable : Primus::Experiment::Blake2b::Unavailable
    raise klass, message
  end

  def assessment_identity(data)
    backend = if data.dig("check", "algorithm") == "blake512"
                data.fetch("backend").slice(*BLAKE512_IDENTITY_KEYS, "error_class")
              else
                data.fetch("backend").reject { |key, _value| key == "error_message" }
              end
    identity = { "output_sha256" => data["output_sha256"], "policy" => data["policy"],
                 "check" => data["check"], "backend" => backend,
                 "ruby_version" => RUBY_VERSION, "code" => @log_entry.data["git_head"] }
    Digest::SHA256.hexdigest(JSON.generate(sorted(identity)))
  end

  def evaluation_expectation
    if @experiment.v2?
      return @experiment.v2_expectation.merge(
        "algorithm" => @experiment.checks.first["algorithm"]
      ) if @experiment.checks.first["strategy"] == "hash"
      return @experiment.expected_bytes
    end
    if @experiment.expectation["kind"] == "hash"
      @experiment.expectation
    else
      @experiment.expected_bytes
    end
  end

  def produce_observation
    page = Primus::LiberPrimus::Page.new(
      number: @experiment.v2? ? @experiment.v2_page_number : @experiment.input.fetch("page_number"),
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
    return translated if @experiment.v2? && @experiment.recipe["id"] == "latin"
    return translated if !@experiment.v2? && @experiment.operation == "runes_to_latin"

    parameters = @experiment.v2? ? @experiment.recipe.fetch("parameters") : @experiment.parameters
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
    identity[:hash_runtime] = fingerprint_runtime if @hash_runtime
    Digest::SHA256.hexdigest(JSON.generate(sorted(identity)))
  end

  def hash_runtime
    if @experiment.v2? && @experiment.checks.is_a?(Array) &&
        @experiment.checks.first.is_a?(Hash)
      case @experiment.checks.first["algorithm"]
      when "blake2b512" then return Primus::Experiment::Blake2b.new.runtime
      when "blake512" then return Primus::Experiment::Blake512.new.runtime
      end
    end
    case @experiment.id
    when "page-57-latin-blake2b512"
      Primus::Experiment::Blake2b.new.runtime
    when "page-57-latin-blake512"
      Primus::Experiment::Blake512.new.runtime
    end
  end

  def fingerprint_runtime
    return @hash_runtime unless @experiment.id == "page-57-latin-blake512"

    known = @hash_runtime.slice(*BLAKE512_IDENTITY_KEYS)
    known["error_class"] = @hash_runtime["error_class"] unless known["available"]
    known
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
    output = resolved_path(@output_path)
    paths = [@experiment.input_path]
    if @experiment.v2? && @experiment.checks.is_a?(Array)
      paths.concat(@experiment.checks.filter_map { |check|
        check.dig("expectation", "path") if check.is_a?(Hash) && check["expectation"].is_a?(Hash)
      })
    else
      paths << @experiment.expectation_path
    end
    paths.compact.each do |path|
      source = resolved_path(path)
      if source.start_with?("#{output}/") || output == source
        raise ArgumentError,
              "output path overlaps research input"
      end
    end
  end

  def resolved_path(path)
    expanded = File.expand_path(path)
    return File.realpath(expanded) if File.exist?(expanded)
    File.join(resolved_path(File.dirname(expanded)), File.basename(expanded))
  end

  def record_execution_error(error)
    failure = { "stage" => "execution", "type" => error.class.name,
                "message" => error.message }
    if @log_entry.data.key?("assessment_records")
      @log_entry.data["status"] = "error"
      @log_entry.data["errors"] = [failure]
      @log_entry.data["completed_at"] = Time.now.utc.iso8601
      return @log_entry = @store.finish_collection_error(@log_entry)
    end
    @log_entry = @store.finish(
      @log_entry, status: "error", errors: [failure],
                  observation: @observation, assessment: @assessment
    )
  end
end
