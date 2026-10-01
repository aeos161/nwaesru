require "digest"
require "json"
require "open3"
require "tmpdir"

RSpec.describe "Primus::Experiment::Runner" do
  def fixture(name)
    "spec/fixtures/experiments/#{name}"
  end

  def provenance(output_path)
    record_path = Dir.glob("#{output_path}/**/record.json").fetch(0)
    manifest = JSON.parse(File.read(record_path)).fetch("artifacts")
    path = manifest.fetch("provenance.json").fetch("path")
    JSON.parse(File.read(path))
  end

  def source_coordinates(body)
    matches = body.enum_for(:scan, /[\u16a0-\u16ff]/).map { Regexp.last_match }
    matches.each_with_index.map do |match, ordinal|
      prefix = body[0...match.begin(0)]
      [ordinal, match[0], 57, 0, *source_spans(prefix, match), ordinal]
    end
  end

  def source_spans(prefix, match)
    [prefix.bytesize, prefix.bytesize + match[0].bytesize,
     match.begin(0), match.end(0),
     prefix.count("\n"), prefix.rpartition("\n").last.length]
  end

  describe "#run" do
    it "saves original coordinates for translated GP symbols" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(path: fixture("page_57_valid.yml"))
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)

        runner.run
        record_path = Dir.glob("#{output_path}/**/record.json").fetch(0)
        manifest = JSON.parse(File.read(record_path)).fetch("artifacts")
        path = manifest.fetch("provenance.json").fetch("path")
        symbols = JSON.parse(File.read(path))

        expect(symbols.first).to include(
          "ordinal" => 0, "rune" => "ᛈ", "latin" => "p",
          "page_number" => 57, "occurrence" => 0,
          "byte_start" => 0, "byte_end" => 3,
          "character_start" => 0, "character_end" => 1,
          "line" => 0, "column" => 0, "rune_index" => 0
        )
      end
    end

    it "retains source coordinates for every page 57 rune" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(path: fixture("page_57_valid.yml"))
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        source_path = "data/encoded/liber_primus/page_57.yml"
        body = Psych.safe_load(File.read(source_path)).fetch("body")
        expected = source_coordinates(body)

        runner.run
        symbols = provenance(output_path)
        actual = symbols.map do |symbol|
          symbol.values_at("ordinal", "rune", "page_number", "occurrence",
                           "byte_start", "byte_end", "character_start",
                           "character_end", "line", "column", "rune_index")
        end

        expect(actual).to eq(expected)
      end
    end

    it "keeps a two-letter transliteration tied to one source rune" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(path: fixture("page_57_valid.yml"))
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)

        runner.run
        symbols = provenance(output_path)
        digraph = symbols.detect { |symbol| symbol.fetch("rune_index") == 11 }

        expect(digraph).to include(
          "rune" => "ᚦ", "latin" => "th",
          "byte_start" => 35, "byte_end" => 38,
          "rune_index" => 11
        )
      end
    end

    it "creates a separate attempt when the oracle changes" do
      Dir.mktmpdir do |output_path|
        first_experiment = Primus::Experiment.load(
          path: fixture("page_57_valid.yml"),
        )
        first = Primus::Experiment::Runner.new(
          experiment: first_experiment, output_path: output_path,
        )
        first.run
        changed_experiment = Primus::Experiment.load(
          path: fixture("page_57_mismatch.yml"),
        )
        second = Primus::Experiment::Runner.new(
          experiment: changed_experiment, output_path: output_path,
        )

        second.run

        expect(second.log_entry.run_id).not_to eq(first.log_entry.run_id)
      end
    end

    it "reuses a prior mismatching attempt" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(
          path: fixture("page_57_mismatch.yml"),
        )
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        runner.run
        first_id = runner.log_entry.run_id

        runner.run

        expect(runner.log_entry.run_id).to eq(first_id)
      end
    end

    it "does not execute a prior mismatch again" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(
          path: fixture("page_57_mismatch.yml"),
        )
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        runner.run

        runner.run

        expect(runner.observation).to be_nil
      end
    end

    it "requires a nonblank reason for an explicit rerun" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(path: fixture("page_57_valid.yml"))
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        runner.run

        action = -> { runner.run(rerun: true, reason: " ") }

        expect(action).to raise_error(ArgumentError)
      end
    end

    it "records byte lengths and SHA-256 identities for saved artifacts" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(path: fixture("page_57_valid.yml"))
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)

        runner.run
        path = Dir.glob("#{output_path}/**/record.json").fetch(0)
        manifest = JSON.parse(File.read(path)).fetch("artifacts")
        identities = manifest.values.map do |artifact|
          bytes = File.binread(artifact.fetch("path"))
          [artifact.fetch("bytes"), artifact.fetch("sha256"),
           bytes.bytesize, Digest::SHA256.hexdigest(bytes)]
        end
        valid_identity = satisfy do |size, digest, actual_size, actual_digest|
          size == actual_size && digest == actual_digest
        end

        expect(identities).to all(valid_identity)
      end
    end

    it "persists a completed machine-readable run record" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(path: fixture("page_57_valid.yml"))
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)

        runner.run
        records = Dir.glob("#{output_path}/**/record.json")
        saved = JSON.parse(File.read(records.fetch(0)))

        expect(saved).to include("run_id" => runner.log_entry.run_id,
                                 "status" => "matched",
                                 "comparison" => "match")
      end
    end

    it "saves one record for a completed attempt" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(path: fixture("page_57_valid.yml"))
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)

        runner.run

        expect(Dir.glob("#{output_path}/**/record.json").size).to eq(1)
      end
    end

    it "records the definition, runtime, and Git identity used for execution" do
      Dir.mktmpdir do |output_path|
        definition = fixture("page_57_valid.yml")
        experiment = Primus::Experiment.load(path: definition)
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        git_head, _status = Open3.capture2("git", "rev-parse", "HEAD")

        runner.run
        path = Dir.glob("#{output_path}/**/record.json").fetch(0)
        saved = JSON.parse(File.read(path))

        expect([saved.fetch("definition_sha256"), saved.fetch("git_head"),
                saved.fetch("runtime_version")]).to eq(
                  [Digest::SHA256.hexdigest(File.binread(definition)),
                   git_head.strip, RUBY_VERSION],
                )
      end
    end

    it "keeps an earlier Observation unchanged when rerun" do
      Dir.mktmpdir do |output_path|
        experiment = Primus::Experiment.load(path: fixture("page_57_valid.yml"))
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        runner.run
        first = runner.observation
        original_bytes = first.output_bytes.dup

        runner.run(rerun: true, reason: "Check repeatability")

        expect(first.output_bytes).to eq(original_bytes)
      end
    end

    it "rejects an output directory overlapping the encoded input" do
      experiment = Primus::Experiment.load(path: fixture("page_57_valid.yml"))

      action = lambda do
        Primus::Experiment::Runner.new(
          experiment: experiment, output_path: "data/encoded/liber_primus",
        ).run
      end

      expect(action).to raise_error(ArgumentError)
    end

    it "reports persistence failure when output path is a file" do
      Dir.mktmpdir do |directory|
        output_path = File.join(directory, "occupied")
        File.write(output_path, "not a directory")
        experiment = Primus::Experiment.load(path: fixture("page_57_valid.yml"))

        action = lambda do
          Primus::Experiment::Runner.new(
            experiment: experiment, output_path: output_path,
          ).run
        end

        expect(action).to raise_error(SystemCallError)
      end
    end
  end
end
