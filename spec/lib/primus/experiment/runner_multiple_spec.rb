require "json"
require "tmpdir"

RSpec.describe Primus::Experiment::Runner do
  RUNNER_SHA512_DIGEST = "f3fac0115ab06d1a4075731e77fe157ad52b837b9068bf942c95784160578f43a1a72e770f2e2c1b00a1bc2fad39dc66fa78efd28c5cd976ed3a35f3e400bcab"

  def composition(algorithms)
    checks = algorithms.each_with_index.map do |algorithm, index|
      { "id" => "check-#{index + 1}", "strategy" => "hash",
        "algorithm" => algorithm,
        "expectation" => { "digest" => RUNNER_SHA512_DIGEST,
                           "provenance" => "Independent known answer." } }
    end
    Primus::Experiment.from_data(
      "schema_version" => 2, "id" => "page-57-multiple",
      "title" => "Multiple hash checks", "purpose" => "Compare each digest.",
      "input" => { "id" => "page-57", "sha256" => "c7055db0173e43eb231608812f5d52569e4c0817934b1a65427cebf332759fff" },
      "recipe" => { "id" => "latin" },
      "output" => { "policy" => "gp-latin-compatibility-v1" },
      "checks" => checks
    )
  end

  describe "#run" do
    it "surfaces an observation persistence failure before assessment" do
      Dir.mktmpdir do |output_path|
        store = Primus::Experiment::Store.new(output_path: output_path)
        allow(Primus::Experiment::Store).to receive(:new).and_return(store)
        allow(store).to receive(:record_observation).and_raise(Errno::ENOSPC)
        runner = described_class.new(
          experiment: composition(%w[sha512 blake2b512]),
          output_path: output_path
        )

        action = -> { runner.run }

        expect(action).to raise_error(Errno::ENOSPC)
      end
    end

    it "persists the observed output before the first digest calculation" do
      Dir.mktmpdir do |output_path|
        persisted_at_digest = false
        backend = instance_double(Primus::Experiment::Blake2b)
        allow(backend).to receive(:runtime).and_return("available" => true)
        allow(backend).to receive(:hexdigest) do |bytes|
          record_path = Dir.glob("#{output_path}/*/*/record.json").fetch(0)
          artifact = JSON.parse(File.binread(record_path)).fetch("artifacts").fetch("output.txt")
          persisted_at_digest = File.binread(artifact.fetch("path")) == bytes
          '0' * 128
        end
        allow(Primus::Experiment::Blake2b).to receive(:new).and_return(backend)
        runner = described_class.new(
          experiment: composition(%w[blake2b512 sha512]),
          output_path: output_path
        )

        runner.run

        expect(persisted_at_digest).to be(true)
      end
    end

    it "retains a later SHA-512 match after a BLAKE2b runtime probe raises" do
      Dir.mktmpdir do |output_path|
        backend = instance_double(Primus::Experiment::Blake2b)
        allow(backend).to receive(:runtime).and_raise(
          Primus::Experiment::Blake2b::Unavailable, "probe failed"
        )
        allow(Primus::Experiment::Blake2b).to receive(:new).and_return(backend)
        runner = described_class.new(
          experiment: composition(%w[blake2b512 sha512]),
          output_path: output_path
        )

        runner.run

        expect(runner.log_entry.data).to include(
          "status" => "error", "matching_outcome" => "matched",
          "completion_summary" => { "match" => 1, "mismatch" => 0, "error" => 1 }
        )
      end
    end

    it "retains a later SHA-512 match after BLAKE2b digest calculation raises" do
      Dir.mktmpdir do |output_path|
        backend = instance_double(Primus::Experiment::Blake2b)
        allow(backend).to receive(:runtime).and_return("available" => true)
        allow(backend).to receive(:hexdigest).and_raise(
          Primus::Experiment::Blake2b::Unavailable, "digest failed"
        )
        allow(Primus::Experiment::Blake2b).to receive(:new).and_return(backend)
        runner = described_class.new(
          experiment: composition(%w[blake2b512 sha512]),
          output_path: output_path
        )

        runner.run

        expect(runner.log_entry.data).to include(
          "status" => "error", "matching_outcome" => "matched",
          "completion_summary" => { "match" => 1, "mismatch" => 0, "error" => 1 }
        )
      end
    end

    it "keeps a negative outcome when a mismatch accompanies a backend error" do
      Dir.mktmpdir do |output_path|
        backend = instance_double(Primus::Experiment::Blake2b)
        allow(backend).to receive(:runtime).and_raise(
          Primus::Experiment::Blake2b::Unavailable, "probe failed"
        )
        allow(Primus::Experiment::Blake2b).to receive(:new).and_return(backend)
        experiment = composition(%w[blake2b512 sha512])
        experiment.checks.last.fetch("expectation")["digest"] = '0' * 128
        runner = described_class.new(experiment: experiment,
                                     output_path: output_path)

        runner.run

        expect(runner.log_entry.data).to include(
          "status" => "error", "matching_outcome" => "no_match",
          "completion_summary" => { "match" => 0, "mismatch" => 1, "error" => 1 }
        )
      end
    end

    it "records no match when every backend probe fails" do
      Dir.mktmpdir do |output_path|
        blake2b = instance_double(Primus::Experiment::Blake2b)
        blake512 = instance_double(Primus::Experiment::Blake512)
        allow(blake2b).to receive(:runtime).and_raise(
          Primus::Experiment::Blake2b::Unavailable, "probe failed"
        )
        allow(blake512).to receive(:runtime).and_raise(
          Primus::Experiment::Blake512::Unavailable, "probe failed"
        )
        allow(Primus::Experiment::Blake2b).to receive(:new).and_return(blake2b)
        allow(Primus::Experiment::Blake512).to receive(:new).and_return(blake512)
        runner = described_class.new(
          experiment: composition(%w[blake2b512 blake512]),
          output_path: output_path
        )

        runner.run

        expect(runner.log_entry.data).to include(
          "status" => "error", "matching_outcome" => "no_match",
          "completion_summary" => { "match" => 0, "mismatch" => 0, "error" => 2 }
        )
      end
    end
  end
end
