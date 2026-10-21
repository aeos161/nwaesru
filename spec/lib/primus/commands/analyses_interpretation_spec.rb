require "json"
require "open3"
require "tmpdir"

RSpec.describe Primus::Commands::Analyses do
  include SavedAnalysisHelper

  def analyze(root, experiment_id, run_id)
    Open3.capture3(
      "bin/primus", "analyses", "run", experiment_id, run_id,
      "--definition", "experiments/analyses/final-symbol-statistics.yml",
      "--output-path", root,
    )
  end

  def review(root, experiment_id, run_id)
    Open3.capture3("bin/primus", "analyses", "review", experiment_id,
                   run_id, "--output-path", root)
  end

  def analysis_record(root, experiment_id, run_id)
    path = Dir.glob(File.join(root, experiment_id, run_id,
                              "analyses", "*", "record.json")).fetch(0)
    [path, JSON.parse(File.binread(path))]
  end

  describe "#execute" do
    it "keeps canonical multi-letter GP expansions in the Latin measurement" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(
          root, runes: %w[ᚢ ᚳ ᛋ ᛝ ᛡ], letters: %w[u c s ng io],
          output: "ucsngio",
        )

        _stdout, stderr, status = analyze(root, experiment_id, run_id)
        raise stderr unless status.success?
        _path, record = analysis_record(root, experiment_id, run_id)
        latin = record.fetch("results").last.fetch("result")

        expect(latin.fetch("sample_size")).to eq(7)
      end
    end

    it "prints one English comparison for each measured representation" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)

        stdout, stderr, status = analyze(root, experiment_id, run_id)
        raise stderr unless status.success?

        expect(stdout.scan("English comparison:").length).to eq(2)
      end
    end

    it "labels an all-identical rune sample as concentrated without claiming English" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(
          root, runes: %w[ᚦ ᚦ ᚦ], letters: %w[th th th], output: "ththth",
        )

        stdout, stderr, status = analyze(root, experiment_id, run_id)
        raise stderr unless status.success?

        expect(stdout).to include("More concentrated than both solved English controls; " \
                                  "higher IC does not mean closer to English.")
      end
    end

    it "prints the same limited-comparison warning for both computed results" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)

        stdout, stderr, status = analyze(root, experiment_id, run_id)
        raise stderr unless status.success?

        expect(stdout.scan("Limited comparison: two short solved controls").length).to eq(2)
      end
    end

    it "persists the named reference set with both measurements" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)

        _stdout, stderr, status = analyze(root, experiment_id, run_id)
        raise stderr unless status.success?
        _path, record = analysis_record(root, experiment_id, run_id)

        expect(record.fetch("results").map { |entry| entry.fetch("result") }).to all(
          include("interpretation" => include("reference_set_id" =>
            "solved-gp-english-controls-v1")),
        )
      end
    end

    it "displays each computed comparison's sample size as N" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)

        stdout, stderr, status = analyze(root, experiment_id, run_id)
        raise stderr unless status.success?

        expect(stdout.scan(/\bN=(?:3|5)\b/).sort).to eq(["N=3", "N=5"])
      end
    end

    it "persists the two independently frozen GP rune control fractions" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)

        _stdout, stderr, status = analyze(root, experiment_id, run_id)
        raise stderr unless status.success?
        _path, record = analysis_record(root, experiment_id, run_id)
        interpretation = record.fetch("results").first.fetch("result").fetch("interpretation")
        controls = interpretation.fetch("references")

        expect(controls.map { |reference| reference.slice("id", "sample_size",
                                                       "numerator", "denominator") }).to eq(
          [{ "id" => "page-56", "sample_size" => 85,
             "numerator" => 500, "denominator" => 7140 },
           { "id" => "page-57", "sample_size" => 95,
             "numerator" => 560, "denominator" => 8930 }],
        )
      end
    end

    it "persists the two independently frozen expanded-Latin control fractions" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)

        _stdout, stderr, status = analyze(root, experiment_id, run_id)
        raise stderr unless status.success?
        _path, record = analysis_record(root, experiment_id, run_id)
        interpretation = record.fetch("results").last.fetch("result").fetch("interpretation")
        controls = interpretation.fetch("references")

        expect(controls.map { |reference| reference.slice("id", "sample_size",
                                                       "numerator", "denominator") }).to eq(
          [{ "id" => "page-56", "sample_size" => 91,
             "numerator" => 638, "denominator" => 8190 },
           { "id" => "page-57", "sample_size" => 100,
             "numerator" => 640, "denominator" => 9900 }],
        )
      end
    end
  end

  describe "#review" do
    it "rejects a malformed present interpretation instead of treating it as historical" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)
        _stdout, stderr, status = analyze(root, experiment_id, run_id)
        raise stderr unless status.success?
        path, record = analysis_record(root, experiment_id, run_id)
        record.fetch("results").first.fetch("result")["interpretation"] =
          { "schema_version" => 999 }
        File.binwrite(path, JSON.pretty_generate(record))

        _stdout, _stderr, status = review(root, experiment_id, run_id)

        expect(status.success?).to be_falsy
      end
    end

    it "prints a retained English comparison for each measured representation" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)
        _stdout, stderr, status = analyze(root, experiment_id, run_id)
        raise stderr unless status.success?

        stdout, stderr, status = review(root, experiment_id, run_id)
        raise stderr unless status.success?

        expect(stdout.scan("English comparison:").length).to eq(2)
      end
    end

    it "explains why a historical result without a payload cannot be compared" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)
        _stdout, stderr, status = analyze(root, experiment_id, run_id)
        raise stderr unless status.success?
        path, record = analysis_record(root, experiment_id, run_id)
        record.fetch("results").each { |entry| entry.fetch("result").delete("interpretation") }
        File.binwrite(path, JSON.pretty_generate(record))

        stdout, stderr, status = review(root, experiment_id, run_id)
        raise stderr unless status.success?

        expect(stdout.scan("this historical analysis did not retain an interpretation").length).
          to eq(2)
      end
    end

    it "retains the saved judgment after the source artifact is removed" do
      Dir.mktmpdir do |root|
        experiment_id, run_id = independent_three_rune_observation(root)
        _stdout, stderr, status = analyze(root, experiment_id, run_id)
        raise stderr unless status.success?
        source_path = File.join(root, experiment_id, run_id, "source.yml")
        File.delete(source_path)

        stdout, stderr, status = review(root, experiment_id, run_id)
        raise stderr unless status.success?

        expect(stdout.scan("English comparison:").length).to eq(2)
      end
    end
  end
end
