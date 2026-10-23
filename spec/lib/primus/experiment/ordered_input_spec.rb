require "digest"
require "fileutils"
require "json"
require "open3"
require "tmpdir"

RSpec.describe Primus::Experiment do
  def with_ordered_input(bodies: ["ᚳ-ᚻ", "ᚷᚻ"], page_numbers: [99, 100],
                         skip_sequence: [])
    directory = Dir.mktmpdir
    begin
      repository = File.join(directory, "repository")
      _stdout, stderr, status = Open3.capture3(
        "git", "clone", "--quiet", "--local", "--no-hardlinks", Dir.pwd, repository
      )
      raise "Test repository clone failed: #{stderr}" unless status.success?

      Dir.chdir(repository) do
        pages = page_numbers.zip(bodies).map do |number, body|
          path = "data/encoded/liber_primus/page_#{number}.yml"
          File.binwrite(path, Psych.dump("body" => body))
          { "id" => "page-#{number}", "sha256" => Digest::SHA256.file(path).hexdigest }
        end
        definition = {
          "schema_version" => 2, "id" => "ordered-input-control",
          "title" => "Ordered two-page control",
          "purpose" => "Check continuous GP and retained source evidence.",
          "input" => { "pages" => pages },
          "steps" => [
            { "id" => "totient", "operation" => "totient",
              "parameters" => { "modulus" => 29, "prime_start" => 2,
                                "skip_sequence" => skip_sequence } },
            { "id" => "letters", "operation" => "latin", "parameters" => {} }
          ],
          "output" => { "policy" => "gp-latin-compatibility-v1" },
          "checks" => [{ "id" => "check-1", "strategy" => "hash",
                         "algorithm" => "sha512",
                         "expectation" => { "digest" => "0" * 128,
                                            "provenance" => "Synthetic negative control." } }]
        }
        definition_path = "experiments/definitions/ordered-input-control.yml"
        File.binwrite(definition_path, Psych.dump(definition))
        experiment = described_class.load(path: definition_path)
        yield experiment, File.join(directory, "runs"), definition
      end
    ensure
      FileUtils.rm_rf(directory)
    end
  end

  def run_ordered(experiment, output_path)
    runner = Primus::Experiment::Runner.new(experiment: experiment,
                                            output_path: output_path)
    runner.run
    runner
  end

  def checkpoint_rows(runner, step_id, kind)
    item = runner.log_entry.data.fetch("checkpoints").find do |checkpoint|
      checkpoint.fetch("step_id") == step_id
    end
    JSON.parse(File.binread(item.fetch(kind).fetch("path")))
  end

  def checkpoint_bytes(runner, step_id)
    item = runner.log_entry.data.fetch("checkpoints").find do |checkpoint|
      checkpoint.fetch("step_id") == step_id
    end
    File.binread(item.fetch("output").fetch("path"))
  end

  def saved_record_path(runner, output_path)
    File.join(output_path, runner.log_entry.data.fetch("experiment_id"),
              runner.log_entry.run_id, "record.json")
  end

  describe "#valid?" do
    it "accepts two ordered whole-page inputs" do
      with_ordered_input do |experiment|
        expect(experiment).to be_valid
      end
    end

    it "accepts repeated page IDs as separate occurrences" do
      with_ordered_input(bodies: ["ᚳ-ᚻ", "ᚳ-ᚻ"], page_numbers: [99, 99]) do |experiment|
        expect(experiment).to be_valid
      end
    end

    it "accepts a skip at the last global GP ordinal" do
      with_ordered_input(skip_sequence: [3]) do |experiment|
        expect(experiment).to be_valid
      end
    end
  end

  describe "#run" do
    it "captures the exact concatenation without a boundary byte" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        actual = checkpoint_bytes(runner, "original")

        expect(actual).to eq("ᚳ-ᚻᚷᚻ")
      end
    end

    it "continues the prime sequence across the source boundary" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        actual = checkpoint_bytes(runner, "totient")

        expect(actual).to eq("ᚱ-ᚷᚦᚦ")
      end
    end

    it "renders the composed stream once with the compatibility boundary" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        actual = runner.observation.output_bytes

        expect(actual).to eq("r g\nthth")
      end
    end

    it "retains the independent original byte digest" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        item = runner.log_entry.data.fetch("checkpoints").first

        expect(item.fetch("output").fetch("sha256")).to eq(
          "370480baec1ce0733ce2dbc480c8c7676169ff5702d6cbb5cce1b28501ba406a"
        )
      end
    end

    it "retains the independent totient byte digest" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        item = runner.log_entry.data.fetch("checkpoints")[1]

        expect(item.fetch("output").fetch("sha256")).to eq(
          "a16e1440b8d3096cd9603f2a32310acf7990628f24fd7b96cb7efb6209cfd6aa"
        )
      end
    end

    it "retains the independent final Latin digest" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        item = runner.log_entry.data.fetch("checkpoints").last

        expect(item.fetch("output").fetch("sha256")).to eq(
          "64576525ccfda6ed5e37a3a15e64051f6a762836745d588280b667760fb2b5ba"
        )
      end
    end

    it "keeps the second page's first rune distinct from a prime-2 reset" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        third_rune = checkpoint_rows(runner, "totient", "symbols")[2].fetch("rune")

        expect(third_rune).to eq("ᚦ")
      end
    end

    it "applies a configured skip at the second page's global ordinal" do
      with_ordered_input(skip_sequence: [2]) do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        actual = checkpoint_bytes(runner, "totient")

        expect(actual).to eq("ᚱ-ᚷᚷᚱ")
      end
    end

    it "retains source-relative coordinates and global GP ordinals" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        coordinates = checkpoint_rows(runner, "original", "symbols").map do |symbol|
          symbol.values_at("ordinal", "page_number", "occurrence", "byte_start",
                           "byte_end", "character_start", "character_end",
                           "line", "column", "rune_index")
        end

        expect(coordinates).to eq([
          [0, 99, 0, 0, 3, 0, 1, 0, 0, 0],
          [1, 99, 0, 4, 7, 2, 3, 0, 2, 1],
          [2, 100, 1, 0, 3, 0, 1, 0, 0, 0],
          [3, 100, 1, 3, 6, 1, 2, 0, 1, 1]
        ])
      end
    end

    it "slices final rune provenance from each matching occurrence" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        original_runes = runner.observation.provenance.map { |item| item.fetch("rune") }

        expect(original_runes).to eq(%w[ᚳ ᚻ ᚷ ᚻ])
      end
    end

    it "does not leak prime state through an intervening run" do
      with_ordered_input do |experiment, output_path|
        run_ordered(experiment, output_path)
        unrelated = Primus::Experiment.from_data(
          Psych.safe_load(File.binread("spec/fixtures/experiments/page_57_checkpoints.yml"))
        )
        run_ordered(unrelated, output_path)
        second = Primus::Experiment::Runner.new(experiment: experiment,
                                                 output_path: output_path)

        second.run(rerun: true, reason: "Check continuous state isolation")

        expect(second.observation.output_bytes).to eq("r g\nthth")
      end
    end

    it "distinguishes repeated IDs by occurrence in saved symbols" do
      with_ordered_input(bodies: ["ᚳ-ᚻ", "ᚳ-ᚻ"], page_numbers: [99, 99]) do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        identities = checkpoint_rows(runner, "original", "symbols").map do |symbol|
          symbol.values_at("page_number", "occurrence", "rune_index")
        end

        expect(identities).to eq([[99, 0, 0], [99, 0, 1],
                                  [99, 1, 0], [99, 1, 1]])
      end
    end

    it "records half-open ranges for the ordered original bodies" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        ranges = runner.log_entry.data.fetch("source_manifest").map do |source|
          source.values_at("page_number", "occurrence", "byte_start", "byte_end")
        end

        expect(ranges).to eq([[99, 0, 0, 7], [100, 1, 7, 13]])
      end
    end

    it "stores an explicit aggregate source artifact with no inserted separator" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        artifact = runner.log_entry.data.fetch("artifacts").fetch("source-body.txt")

        expect(File.binread(artifact.fetch("path"))).to eq("ᚳ-ᚻᚷᚻ")
      end
    end

    it "stores a separate source YAML snapshot for each occurrence" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        artifacts = runner.log_entry.data.fetch("artifacts")
        snapshots = %w[source-0.yml source-1.yml].map do |name|
          Psych.safe_load(File.binread(artifacts.fetch(name).fetch("path"))).fetch("body")
        end

        expect(snapshots).to eq(["ᚳ-ᚻ", "ᚷᚻ"])
      end
    end

    it "stores a separate exact body snapshot for each occurrence" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)

        artifacts = runner.log_entry.data.fetch("artifacts")
        snapshots = %w[source-0-body.txt source-1-body.txt].map do |name|
          File.binread(artifacts.fetch(name).fetch("path"))
        end

        expect(snapshots).to eq(["ᚳ-ᚻ", "ᚷᚻ"])
      end
    end

    it "changes execution identity when member order changes" do
      with_ordered_input do |experiment, output_path, definition|
        first = run_ordered(experiment, output_path)
        definition.fetch("input").fetch("pages").reverse!
        reversed = described_class.from_data(definition)

        second = run_ordered(reversed, output_path)

        expect(second.log_entry.data.fetch("execution_identity")).not_to eq(
          first.log_entry.data.fetch("execution_identity")
        )
      end
    end

    it "supports original-stage analysis from retained sources alone" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)
        File.delete("data/encoded/liber_primus/page_99.yml")
        File.delete("data/encoded/liber_primus/page_100.yml")
        reader = Primus::Analysis::ObservationReader.new(
          output_path: output_path, experiment_id: experiment.id,
          run_id: runner.log_entry.run_id, stage: "original"
        )

        observation = reader.to_observation

        expect(observation.symbols("gp-runes-v1")).to eq(%w[ᚳ ᚻ ᚷ ᚻ])
      end
    end
  end

  describe "Primus::Experiment::Store#review" do
    it "reads retained ordered evidence after both live source files disappear" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)
        File.delete("data/encoded/liber_primus/page_99.yml")
        File.delete("data/encoded/liber_primus/page_100.yml")
        store = Primus::Experiment::Store.new(output_path: output_path)

        reviewed = store.review(id: experiment.id, run_id: runner.log_entry.run_id)

        expect(reviewed.data.fetch("source_manifest").map { |item| item.fetch("occurrence") }).to eq([0, 1])
      end
    end

    it "rejects a changed second member body snapshot" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)
        artifact = runner.log_entry.data.fetch("artifacts").fetch("source-1-body.txt")
        File.binwrite(artifact.fetch("path"), "ᚠᚠ")
        store = Primus::Experiment::Store.new(output_path: output_path)

        action = -> { store.review(id: experiment.id, run_id: runner.log_entry.run_id) }

        expect(action).to raise_error(Primus::Experiment::Store::ReadError)
      end
    end

    it "rejects a swapped ordered source manifest" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)
        path = saved_record_path(runner, output_path)
        record = JSON.parse(File.binread(path))
        record.fetch("source_manifest").reverse!
        File.binwrite(path, JSON.pretty_generate(record))
        store = Primus::Experiment::Store.new(output_path: output_path)

        action = -> { store.review(id: experiment.id, run_id: runner.log_entry.run_id) }

        expect(action).to raise_error(Primus::Experiment::Store::ReadError)
      end
    end

    it "rejects an aggregate boundary that omits one member byte" do
      with_ordered_input do |experiment, output_path|
        runner = run_ordered(experiment, output_path)
        path = saved_record_path(runner, output_path)
        record = JSON.parse(File.binread(path))
        record.fetch("source_manifest")[1]["byte_start"] = 8
        File.binwrite(path, JSON.pretty_generate(record))
        store = Primus::Experiment::Store.new(output_path: output_path)

        action = -> { store.review(id: experiment.id, run_id: runner.log_entry.run_id) }

        expect(action).to raise_error(Primus::Experiment::Store::ReadError)
      end
    end
  end
end
