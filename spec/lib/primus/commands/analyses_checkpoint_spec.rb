require "json"
require "open3"
require "tmpdir"

RSpec.describe Primus::Commands::Analyses do
  include SavedCheckpointAnalysisHelper

  def analyze(output_path, id, run_id, definition)
    Open3.capture3("bin/primus", "analyses", "run", id, run_id,
                   "--definition", definition, "--output-path", output_path)
  end

  def analyze_successfully(output_path, id, run_id, definition)
    _stdout, stderr, status = analyze(output_path, id, run_id, definition)
    raise "Analysis failed: #{stderr}" unless status.success?
  end

  def saved_analysis(output_path, id, run_id)
    path = Dir.glob(File.join(output_path, id, run_id, "analyses", "*", "record.json")).fetch(0)
    JSON.parse(File.binread(path))
  end

  describe "#execute" do
    it "keeps the existing final rune sample size on a captured chain" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "final")

          analyze_successfully(output_path, id, run_id, definition)
          result = saved_analysis(output_path, id, run_id).fetch("results").first.fetch("result")

          expect(result.fetch("sample_size")).to eq(4)
        end
      end
    end

    it "counts original GP runes from the captured source body" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "original")

          analyze_successfully(output_path, id, run_id, definition)
          frequencies = saved_analysis(output_path, id, run_id).fetch("results").first.
                        fetch("result").fetch("frequencies")

          expect(frequencies.select { |bin| bin.fetch("count").positive? }.
            map { |bin| [bin.fetch("symbol"), bin.fetch("count")] }).to eq(
              [["ᚳ", 1], ["ᚻ", 1], ["ᛇ", 1], ["ᛒ", 1]]
            )
        end
      end
    end

    it "counts canonical original Latin expansions" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "original")

          analyze_successfully(output_path, id, run_id, definition)
          frequencies = saved_analysis(output_path, id, run_id).fetch("results").last.
                        fetch("result").fetch("frequencies")

          expect(frequencies.select { |bin| bin.fetch("count").positive? }.
            map { |bin| [bin.fetch("symbol"), bin.fetch("count")] }).to eq(
              [["b", 1], ["c", 1], ["e", 1], ["h", 1], ["o", 1]]
            )
        end
      end
    end

    it "retains the requested checkpoint stage on each result envelope" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "original")

          analyze_successfully(output_path, id, run_id, definition)
          results = saved_analysis(output_path, id, run_id).fetch("results")

          expect(results.map { |entry| entry.fetch("stage") }).to eq(%w[original original])
        end
      end
    end

    it "binds the original profile to its independent output checksum" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "original")

          analyze_successfully(output_path, id, run_id, definition)
          profile = saved_analysis(output_path, id, run_id).fetch("results").first.fetch("profile")

          expect(profile.fetch("output_sha256")).to eq(
            "5f80eab25d255b791df82f22560a8319c4d38a18296d8ef2304caf7ae506419b"
          )
        end
      end
    end

    it "names checkpoint symbols as the selected profile artifact" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "original")

          analyze_successfully(output_path, id, run_id, definition)
          profile = saved_analysis(output_path, id, run_id).fetch("results").first.fetch("profile")

          expect(profile.fetch("artifact")).to eq("symbols.json")
        end
      end
    end

    it "measures the first completed transformation checkpoint" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "first")

          analyze_successfully(output_path, id, run_id, definition)
          frequencies = saved_analysis(output_path, id, run_id).fetch("results").first.
                        fetch("result").fetch("frequencies")

          expect(frequencies.select { |bin| bin.fetch("count").positive? }.
            map { |bin| [bin.fetch("symbol"), bin.fetch("count")] }).to eq(
              [["ᚱ", 1], ["ᚻ", 1], ["ᛁ", 1], ["ᛈ", 1]]
            )
        end
      end
    end

    it "measures the second checkpoint's two-letter GP expansion" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "second")

          analyze_successfully(output_path, id, run_id, definition)
          frequencies = saved_analysis(output_path, id, run_id).fetch("results").last.
                        fetch("result").fetch("frequencies")

          expect(frequencies.select { |bin| bin.fetch("count").positive? }.
            map { |bin| [bin.fetch("symbol"), bin.fetch("count")] }).to eq(
              [["h", 1], ["i", 1], ["r", 1], ["t", 1], ["w", 1]]
            )
        end
      end
    end

    it "retains the requested final alias alongside its resolved terminal step" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "final")

          analyze_successfully(output_path, id, run_id, definition)
          record = saved_analysis(output_path, id, run_id)

          expect(record.fetch("checkpoint")).to include(
            "requested_stage" => "final", "step_id" => "letters"
          )
        end
      end
    end

    it "keeps the terminal step selector distinct from the final alias" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "letters")

          analyze_successfully(output_path, id, run_id, definition)
          record = saved_analysis(output_path, id, run_id)

          expect(record.fetch("checkpoint")).to include(
            "requested_stage" => "letters", "step_id" => "letters"
          )
        end
      end
    end

    it "gives final and its terminal step equal measurements" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          final_definition = checkpoint_analysis_definition(root, stage: "final")
          analyze_successfully(output_path, id, run_id, final_definition)
          final_result = saved_analysis(output_path, id, run_id).fetch("results").map {
            |entry| entry.fetch("result")
          }
          first_path = Dir.glob(File.join(output_path, id, run_id, "analyses", "*", "record.json")).fetch(0)
          terminal_definition = checkpoint_analysis_definition(root, stage: "letters")

          analyze_successfully(output_path, id, run_id, terminal_definition)
          paths = Dir.glob(File.join(output_path, id, run_id, "analyses", "*", "record.json"))
          second_path = (paths - [first_path]).fetch(0)
          terminal_result = JSON.parse(File.binread(second_path)).fetch("results").map {
            |entry| entry.fetch("result")
          }

          expect(terminal_result).to eq(final_result)
        end
      end
    end

    it "retains the independently calculated nonzero original rune IC" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root, source_body: "ᚦᚪᚦ") do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "original")

          analyze_successfully(output_path, id, run_id, definition)
          ic = saved_analysis(output_path, id, run_id).fetch("results").first.
               fetch("result").fetch("ic")

          expect(ic).to include("numerator" => 2, "denominator" => 6,
                                "value" => (1.0 / 3))
        end
      end
    end

    it "retains the independently calculated nonzero original Latin IC" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root, source_body: "ᚦᚪᚦ") do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "original")

          analyze_successfully(output_path, id, run_id, definition)
          ic = saved_analysis(output_path, id, run_id).fetch("results").last.
               fetch("result").fetch("ic")

          expect(ic).to include("numerator" => 4, "denominator" => 20,
                                "value" => (1.0 / 5))
        end
      end
    end

    it "excludes passthrough ASCII words and digits from original GP counts" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root, source_body: "ᚦᚪᚦ WORD 123!",
                                           final_text: "ealf WORD 123!") do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "original")

          analyze_successfully(output_path, id, run_id, definition)
          result = saved_analysis(output_path, id, run_id).fetch("results").first.fetch("result")

          expect(result.fetch("sample_size")).to eq(3)
        end
      end
    end

    it "excludes passthrough ASCII words and digits from expanded Latin counts" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root, source_body: "ᚦᚪᚦ WORD 123!",
                                           final_text: "ealf WORD 123!") do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "original")

          analyze_successfully(output_path, id, run_id, definition)
          result = saved_analysis(output_path, id, run_id).fetch("results").last.fetch("result")

          expect(result.fetch("sample_size")).to eq(5)
        end
      end
    end

    it "rejects an unknown declared step before reserving an analysis" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "unknown")

          analyze(output_path, id, run_id, definition)
          paths = Dir.glob(File.join(output_path, id, run_id, "analyses", "*"))

          expect(paths).to be_empty
        end
      end
    end

    it "allows the original capture of a finished failed attempt" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root, failure: true) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "original")

          analyze_successfully(output_path, id, run_id, definition)
          records = Dir.glob(File.join(output_path, id, run_id, "analyses", "*", "record.json"))

          expect(records.size).to eq(1)
        end
      end
    end

    it "allows the first completed step of a finished failed attempt" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root, failure: true) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "first")

          analyze_successfully(output_path, id, run_id, definition)
          records = Dir.glob(File.join(output_path, id, run_id, "analyses", "*", "record.json"))

          expect(records.size).to eq(1)
        end
      end
    end

    it "rejects an uncaptured checkpoint of a finished failed attempt" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root, failure: true) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "second")

          analyze(output_path, id, run_id, definition)
          paths = Dir.glob(File.join(output_path, id, run_id, "analyses", "*"))

          expect(paths).to be_empty
        end
      end
    end
  end

  describe "#review" do
    it "shows the retained original selection after its definition changes" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "original")
          analyze_successfully(output_path, id, run_id, definition)
          checkpoint_analysis_definition(root, stage: "final")

          stdout, stderr, status = Open3.capture3(
            "bin/primus", "analyses", "review", id, run_id,
            "--output-path", output_path
          )
          raise "Review failed: #{stderr}" unless status.success?

          expect(stdout).to include("original")
        end
      end
    end

    it "shows the selected checkpoint digest from retained evidence" do
      Dir.mktmpdir do |root|
        with_checkpoint_analysis_run(root) do |output_path, id, run_id|
          definition = checkpoint_analysis_definition(root, stage: "first")
          analyze_successfully(output_path, id, run_id, definition)
          path = File.join(output_path, id, run_id, "record.json")
          record = JSON.parse(File.binread(path))
          digest = record.fetch("checkpoints")[1].fetch("output").fetch("sha256")

          stdout, _stderr, _status = Open3.capture3(
            "bin/primus", "analyses", "review", id, run_id,
            "--output-path", output_path
          )

          expect(stdout).to include(digest)
        end
      end
    end
  end
end
