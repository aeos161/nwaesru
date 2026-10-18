require "digest"
require "fileutils"
require "json"
require "open3"
require "tmpdir"

RSpec.describe Primus::Experiment::Runner do
  ORACLE = {
    "original" => ["ᚳᚻ ᛇᛒ\n", "5f80eab25d255b791df82f22560a8319c4d38a18296d8ef2304caf7ae506419b"],
    "first" => ["ᚱᚻ ᛁᛈ\n", "9e2738c5fb38ea75df0825f3711630c266e9f085e60a754c75a51491fdb20927"],
    "second" => ["ᚦᚱ ᛁᚹ\n", "fc4e037896f6364deed05acba06439355833e7fd3eacb6d08f008c061c677495"],
    "letters" => ["thr iw", "026488a6a5365ca402a28c3821ebca0e470d08440059908fd4388ddc8c1c5ed3"]
  }.freeze

  def with_synthetic_experiment(source_body: "ᚳᚻ ᛇᛒ\n", skip_all: false)
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      _stdout, stderr, status = Open3.capture3(
        "git", "clone", "--quiet", "--local", "--no-hardlinks", Dir.pwd, repository
      )
      raise "Test repository clone failed: #{stderr}" unless status.success?
      source = File.join(repository, "data/encoded/liber_primus/page_99.yml")
      expected = File.join(repository, "experiments/expected/synthetic-chain.txt")
      File.binwrite(source, Psych.dump("body" => source_body))
      File.binwrite(expected, ORACLE.fetch("letters").first)
      definition = {
        "schema_version" => 2, "id" => "synthetic-chain",
        "title" => "Independent four-rune chain",
        "purpose" => "Check exact intermediate transformation evidence.",
        "input" => { "id" => "page-99", "sha256" => Digest::SHA256.file(source).hexdigest },
        "steps" => [
          { "id" => "first", "operation" => "totient",
            "parameters" => { "modulus" => 29, "prime_start" => 2,
                              "skip_sequence" => [1] } },
          { "id" => "second", "operation" => "totient",
            "parameters" => { "modulus" => 29, "prime_start" => 3,
                              "skip_sequence" => [2] } },
          { "id" => "letters", "operation" => "latin", "parameters" => {} }
        ],
        "output" => { "policy" => "gp-latin-compatibility-v1" },
        "checks" => [{ "id" => "check-1", "strategy" => "plaintext",
                       "expectation" => { "path" => "experiments/expected/synthetic-chain.txt",
                                          "sha256" => ORACLE.fetch("letters").last,
                                          "provenance" => "Independent four-rune calculation." } }]
      }
      if skip_all
        definition.fetch("steps").first(2).each { |step|
          step.fetch("parameters")["skip_sequence"] = [0, 1, 2, 3]
        }
      end
      definition_path = File.join(repository, "experiments/definitions/synthetic-chain.yml")
      File.write(definition_path, Psych.dump(definition))
      Dir.chdir(repository) do
        experiment = Primus::Experiment.load(path: definition_path)
        yield experiment, File.join(directory, "runs")
      end
    end
  end

  def checkpoint_record(runner, step_id)
    runner.log_entry.data.fetch("checkpoints").find { |item| item.fetch("step_id") == step_id }
  end

  describe "#run" do
    it "produces the independently calculated final Latin bytes" do
      with_synthetic_experiment do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)

        runner.run

        expect(runner.observation.output_bytes).to eq("thr iw")
      end
    end

    ORACLE.each do |step_id, (bytes, digest)|
      it "stores exact #{step_id} checkpoint bytes" do
        with_synthetic_experiment do |experiment, output_path|
          runner = described_class.new(experiment: experiment, output_path: output_path)

          runner.run
          artifact = checkpoint_record(runner, step_id).fetch("output")

          expect(File.binread(artifact.fetch("path")).bytes).to eq(bytes.bytes)
        end
      end

      it "stores the independent #{step_id} SHA-256" do
        with_synthetic_experiment do |experiment, output_path|
          runner = described_class.new(experiment: experiment, output_path: output_path)

          runner.run
          artifact = checkpoint_record(runner, step_id).fetch("output")

          expect(artifact.fetch("sha256")).to eq(digest)
        end
      end

      it "records the exact #{step_id} artifact byte length" do
        with_synthetic_experiment do |experiment, output_path|
          runner = described_class.new(experiment: experiment, output_path: output_path)

          runner.run
          artifact = checkpoint_record(runner, step_id).fetch("output")

          expect(artifact.fetch("bytes")).to eq(bytes.bytesize)
        end
      end
    end

    it "assigns a distinct run-scoped ID to every capture" do
      with_synthetic_experiment do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)

        runner.run
        ids = runner.log_entry.data.fetch("checkpoints").map { |item| item.fetch("id") }

        expect(ids.uniq.size).to eq(4)
      end
    end

    it "records each resolved operation and its own parameters" do
      with_synthetic_experiment do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)

        runner.run
        actual = runner.log_entry.data.fetch("checkpoints").map { |item|
          item.slice("operation", "parameters")
        }

        expect(actual).to eq([
          { "operation" => "capture", "parameters" => {} },
          { "operation" => "totient", "parameters" => {
            "modulus" => 29, "prime_start" => 2, "skip_sequence" => [1]
          } },
          { "operation" => "totient", "parameters" => {
            "modulus" => 29, "prime_start" => 3, "skip_sequence" => [2]
          } },
          { "operation" => "latin", "parameters" => {} }
        ])
      end
    end

    it "keeps two all-skipped totient checkpoints byte-identical" do
      with_synthetic_experiment(skip_all: true) do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)

        runner.run
        first = checkpoint_record(runner, "first").fetch("output")
        second = checkpoint_record(runner, "second").fetch("output")

        expect(File.binread(first.fetch("path"))).to eq(File.binread(second.fetch("path")))
      end
    end

    it "gives byte-identical totient checkpoints different identities" do
      with_synthetic_experiment(skip_all: true) do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)

        runner.run
        first_id = checkpoint_record(runner, "first").fetch("id")
        second_id = checkpoint_record(runner, "second").fetch("id")

        expect(first_id).not_to eq(second_id)
      end
    end

    it "links four ordered captures to their exact predecessor" do
      with_synthetic_experiment do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)

        runner.run
        checkpoints = runner.log_entry.data.fetch("checkpoints")
        links = checkpoints.map { |item| [item.fetch("step_id"), item.fetch("parent_id", nil)] }

        expect(links).to eq([
          ["original", nil], ["first", checkpoints[0].fetch("id")],
          ["second", checkpoints[1].fetch("id")],
          ["letters", checkpoints[2].fetch("id")]
        ])
      end
    end

    it "identifies the terminal capture as the final checkpoint" do
      with_synthetic_experiment do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)

        runner.run
        last = checkpoint_record(runner, "letters")

        expect(runner.log_entry.data.fetch("final_checkpoint_id")).to eq(last.fetch("id"))
      end
    end

    it "keeps the final root artifact equal to the terminal checkpoint" do
      with_synthetic_experiment do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)

        runner.run
        root = runner.log_entry.data.fetch("artifacts").fetch("output.txt")
        terminal = checkpoint_record(runner, "letters").fetch("output")

        expect(root.fetch("sha256")).to eq(terminal.fetch("sha256"))
      end
    end

    it "marks the rune layers as lossless and Latin as compatibility rendering" do
      with_synthetic_experiment do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)

        runner.run
        policies = runner.log_entry.data.fetch("checkpoints").map { |item| item.fetch("policy") }

        expect(policies).to eq([
          "gp-runes-lossless-v1", "gp-runes-lossless-v1",
          "gp-runes-lossless-v1", "gp-latin-compatibility-v1"
        ])
      end
    end

    it "retains every original source coordinate through all four captures" do
      with_synthetic_experiment do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)

        runner.run
        actual = %w[original first second letters].map { |step_id|
          artifact = checkpoint_record(runner, step_id).fetch("symbols")
          symbols = JSON.parse(File.binread(artifact.fetch("path")))
          symbols.map { |symbol|
            symbol.values_at("ordinal", "page_number", "occurrence", "byte_start",
                             "byte_end", "character_start", "character_end",
                             "line", "column", "rune_index")
          }
        }
        source_coordinates = [
          [0, 99, 0, 0, 3, 0, 1, 0, 0, 0],
          [1, 99, 0, 3, 6, 1, 2, 0, 1, 1],
          [2, 99, 0, 7, 10, 3, 4, 0, 3, 2],
          [3, 99, 0, 10, 13, 4, 5, 0, 4, 3]
        ]

        expect(actual).to eq(Array.new(4) { source_coordinates })
      end
    end

    it "retains one GP symbol for the two-letter terminal expansion" do
      with_synthetic_experiment do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)

        runner.run
        artifact = checkpoint_record(runner, "letters").fetch("symbols")
        symbols = JSON.parse(File.binread(artifact.fetch("path")))

        expect(symbols.first).to include("rune" => "ᚦ", "latin" => "th")
      end
    end

    it "records ordered current GP runes at every capture" do
      with_synthetic_experiment do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)

        runner.run
        actual = %w[original first second letters].map { |step_id|
          artifact = checkpoint_record(runner, step_id).fetch("symbols")
          JSON.parse(File.binread(artifact.fetch("path"))).map { |symbol| symbol.fetch("rune") }.join
        }

        expect(actual).to eq(%w[ᚳᚻᛇᛒ ᚱᚻᛁᛈ ᚦᚱᛁᚹ ᚦᚱᛁᚹ])
      end
    end

    it "records the source LF as omitted only by Latin compatibility" do
      with_synthetic_experiment do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)

        runner.run
        artifact = checkpoint_record(runner, "letters").fetch("lexemes")
        lexemes = JSON.parse(File.binread(artifact.fetch("path")))

        expect(lexemes.last).to include("source_byte_start" => 13,
                                        "source_byte_end" => 14,
                                        "rendering" => "omitted")
      end
    end

    it "preserves punctuation, mixed newlines and trailing whitespace in a rune layer" do
      body = "ᚳ,ᚻ\r\n ᛇᛒ\t \n"
      with_synthetic_experiment(source_body: body) do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)

        runner.run
        artifact = checkpoint_record(runner, "first").fetch("output")

        expect(File.binread(artifact.fetch("path")).bytes).to eq("ᚱ,ᚻ\r\n ᛁᛈ\t \n".bytes)
      end
    end

    it "preserves the same answer around an unrelated direct-Latin run" do
      with_synthetic_experiment do |experiment, output_path|
        first = described_class.new(experiment: experiment, output_path: output_path)
        unrelated_definition = Psych.safe_load(File.binread(
          "spec/fixtures/experiments/page_57_valid.yml"
        ))
        unrelated = Primus::Experiment.from_data(unrelated_definition)
        last = described_class.new(experiment: experiment, output_path: output_path)

        first.run
        described_class.new(experiment: unrelated, output_path: output_path).run
        last.run(rerun: true, reason: "Verify independent fresh state")

        expect(last.observation.output_bytes).to eq(first.observation.output_bytes)
      end
    end

    it "retains original and first captures when the second totient layer fails" do
      with_synthetic_experiment do |experiment, output_path|
        calls = 0
        allow(Primus::Document::TotientShift).to receive(:new).and_wrap_original do |original, *args|
          calls += 1
          raise "second layer failed" if calls == 2

          original.call(*args)
        end
        runner = described_class.new(experiment: experiment, output_path: output_path)

        begin
          runner.run
        rescue RuntimeError
          nil
        end

        expect(runner.log_entry.data.fetch("checkpoints").map { |item| item.fetch("step_id") }).to eq(%w[original first])
      end
    end

    it "records the failed step ID and index without a final observation" do
      with_synthetic_experiment do |experiment, output_path|
        calls = 0
        allow(Primus::Document::TotientShift).to receive(:new).and_wrap_original do |original, *args|
          calls += 1
          raise "second layer failed" if calls == 2

          original.call(*args)
        end
        runner = described_class.new(experiment: experiment, output_path: output_path)

        begin
          runner.run
        rescue RuntimeError
          nil
        end

        expect(runner.log_entry.data.fetch("failed_step")).to include(
          "id" => "second", "index" => an_instance_of(Integer), "status" => "error"
        )
      end
    end

    it "rejects a changed checkpoint artifact when reviewing the saved run" do
      with_synthetic_experiment do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)
        runner.run
        artifact = checkpoint_record(runner, "first").fetch("output")
        File.binwrite(artifact.fetch("path"), "corrupt")
        store = Primus::Experiment::Store.new(output_path: output_path)

        action = -> { store.review(id: experiment.id, run_id: runner.log_entry.run_id) }

        expect(action).to raise_error(Primus::Experiment::Store::ReadError)
      end
    end

    it "rejects a contradictory checkpoint parent when reviewing the saved run" do
      with_synthetic_experiment do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)
        runner.run
        record_path = File.join(output_path, experiment.id,
                                runner.log_entry.run_id, "record.json")
        record = JSON.parse(File.binread(record_path))
        record.fetch("checkpoints")[2]["parent_id"] = "unrelated"
        File.binwrite(record_path, JSON.pretty_generate(record))
        store = Primus::Experiment::Store.new(output_path: output_path)

        action = -> { store.review(id: experiment.id, run_id: runner.log_entry.run_id) }

        expect(action).to raise_error(Primus::Experiment::Store::ReadError)
      end
    end

    it "rejects a checkpoint symlink escaping the selected run" do
      with_synthetic_experiment do |experiment, output_path|
        runner = described_class.new(experiment: experiment, output_path: output_path)
        runner.run
        artifact = checkpoint_record(runner, "first").fetch("output")
        path = artifact.fetch("path")
        FileUtils.rm(path)
        File.symlink(File.expand_path("experiments/expected/synthetic-chain.txt"), path)
        store = Primus::Experiment::Store.new(output_path: output_path)

        action = -> { store.review(id: experiment.id, run_id: runner.log_entry.run_id) }

        expect(action).to raise_error(Primus::Experiment::Store::ReadError)
      end
    end

  end
end
