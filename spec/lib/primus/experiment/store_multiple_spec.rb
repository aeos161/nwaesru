require "fileutils"
require "json"
require "tmpdir"

RSpec.describe Primus::Experiment::Store do
  def write_run(directory, reference)
    run_directory = File.join(directory, "page-57-multiple", "run-001")
    FileUtils.mkdir_p(run_directory)
    record = { "schema_version" => 2, "experiment_id" => "page-57-multiple",
               "run_id" => "run-001", "status" => "completed",
               "observation" => nil, "artifacts" => {},
               "assessment_records" => [reference] }
    File.write(File.join(run_directory, "record.json"), JSON.generate(record))
    run_directory
  end

  describe "#review" do
    it "rejects a missing referenced assessment record" do
      Dir.mktmpdir do |output_path|
        write_run(output_path, "assessments/missing/record.json")
        store = described_class.new(output_path: output_path)

        action = -> { store.review(id: "page-57-multiple", run_id: "run-001") }

        expect(action).to raise_error(described_class::ReadError)
      end
    end

    it "rejects an assessment reference that escapes its run directory" do
      Dir.mktmpdir do |output_path|
        run_directory = write_run(output_path, "../other/record.json")
        outside = File.join(File.dirname(run_directory), "other")
        FileUtils.mkdir_p(outside)
        File.write(File.join(outside, "record.json"), JSON.generate("schema_version" => 2))
        store = described_class.new(output_path: output_path)

        action = -> { store.review(id: "page-57-multiple", run_id: "run-001") }

        expect(action).to raise_error(described_class::ReadError)
      end
    end

    it "rejects an unsupported referenced assessment schema" do
      Dir.mktmpdir do |output_path|
        run_directory = write_run(output_path, "assessments/attempt-001/record.json")
        assessment_directory = File.join(run_directory, "assessments", "attempt-001")
        FileUtils.mkdir_p(assessment_directory)
        File.write(File.join(assessment_directory, "record.json"),
                   JSON.generate("schema_version" => 3))
        store = described_class.new(output_path: output_path)

        action = -> { store.review(id: "page-57-multiple", run_id: "run-001") }

        expect(action).to raise_error(described_class::ReadError)
      end
    end
  end
end
