require "digest"
require "json"
require "open3"
require "tmpdir"

RSpec.describe "Primus::Analysis::LogEntry" do
  include SavedAnalysisHelper

  def saved_analysis(root)
    experiment_id, run_id = independent_three_rune_observation(root)
    directory = File.join(root, experiment_id, run_id)
    Open3.capture3(
      "bin/primus", "analyses", "run", experiment_id, run_id,
      "--definition", "experiments/analyses/final-symbol-statistics.yml",
      "--output-path", root,
    )
    [directory, Primus::Analysis::Store.new(directory: File.realpath(directory))]
  end

  describe "#status" do
    it "reports a completed measurement execution" do
      Dir.mktmpdir do |root|
        _directory, store = saved_analysis(root)

        entry = store.review.fetch(0)

        expect(entry.status).to eq("completed")
      end
    end

    it "reports an interrupted execution as running" do
      Dir.mktmpdir do |root|
        directory, store = saved_analysis(root)
        path = Dir.glob(File.join(directory, "analyses", "*", "record.json")).fetch(0)
        record = JSON.parse(File.binread(path))
        record.merge!("status" => "running", "completed_at" => nil,
                      "results" => [], "errors" => [])
        File.binwrite(path, JSON.pretty_generate(record))

        entry = store.review.fetch(0)

        expect(entry.status).to eq("running")
      end
    end
  end

  describe "#experiment_id" do
    it "identifies the observation used by the analysis" do
      Dir.mktmpdir do |root|
        _directory, store = saved_analysis(root)

        entry = store.review.fetch(0)

        expect(entry.experiment_id).to eq("tiny-final")
      end
    end
  end

  describe "#run_id" do
    it "identifies the exact saved observation run" do
      Dir.mktmpdir do |root|
        _directory, store = saved_analysis(root)

        entry = store.review.fetch(0)

        expect(entry.run_id).to eq("20261009T000000-000000000001")
      end
    end
  end

  describe "#measurements" do
    it "returns ordered scientific Results through direct readers" do
      Dir.mktmpdir do |root|
        _directory, store = saved_analysis(root)

        entry = store.review.fetch(0)

        expect(entry.measurements.map(&:representation)).to eq(
          %w[gp-runes-v1 gp-expanded-latin-v1],
        )
      end
    end

    it "keeps a running attempt free of measurements" do
      Dir.mktmpdir do |root|
        directory, store = saved_analysis(root)
        path = Dir.glob(File.join(directory, "analyses", "*", "record.json")).fetch(0)
        record = JSON.parse(File.binread(path))
        record.merge!("status" => "running", "completed_at" => nil,
                      "results" => [], "errors" => [])
        File.binwrite(path, JSON.pretty_generate(record))

        entry = store.review.fetch(0)

        expect(entry.measurements).to be_empty
      end
    end

    it "protects restored measurement bins from caller mutation" do
      Dir.mktmpdir do |root|
        _directory, store = saved_analysis(root)

        entry = store.review.fetch(0)

        expect(entry.measurements.first.frequencies.first).to be_frozen
      end
    end
  end

  describe "#errors" do
    it "retains errors from a failed analysis execution" do
      Dir.mktmpdir do |root|
        directory, store = saved_analysis(root)
        path = Dir.glob(File.join(directory, "analyses", "*", "record.json")).fetch(0)
        record = JSON.parse(File.binread(path))
        record.merge!("status" => "error", "results" => [],
                      "errors" => [{ "type" => "RuntimeError",
                                     "message" => "measurement interrupted" }])
        File.binwrite(path, JSON.pretty_generate(record))

        entry = store.review.fetch(0)

        expect(entry.errors).to eq(["type" => "RuntimeError",
                                    "message" => "measurement interrupted"])
      end
    end

    it "owns the restored error details" do
      Dir.mktmpdir do |root|
        directory, store = saved_analysis(root)
        path = Dir.glob(File.join(directory, "analyses", "*", "record.json")).fetch(0)
        record = JSON.parse(File.binread(path))
        record.merge!("status" => "error", "results" => [],
                      "errors" => [{ "type" => "RuntimeError",
                                     "message" => "measurement interrupted" }])
        File.binwrite(path, JSON.pretty_generate(record))

        entry = store.review.fetch(0)

        expect(entry.errors.first).to be_frozen
      end
    end
  end

  describe "#matches_observation?" do
    it "compares the retained execution to its selected observation" do
      Dir.mktmpdir do |root|
        _directory, store = saved_analysis(root)

        entry = store.review.fetch(0)

        expect(entry.matches_observation?(experiment_id: "tiny-final",
                                          run_id: "20261009T000000-000000000001")).to be_truthy
      end
    end
  end

  describe "#definition_sha256" do
    it "retains the exact definition snapshot digest for review" do
      Dir.mktmpdir do |root|
        _directory, store = saved_analysis(root)
        definition = File.binread("experiments/analyses/final-symbol-statistics.yml")

        entry = store.review.fetch(0)

        expect(entry.definition_sha256).to eq(Digest::SHA256.hexdigest(definition))
      end
    end
  end
end
