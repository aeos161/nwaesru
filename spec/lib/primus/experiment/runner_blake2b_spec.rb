require "json"
require "openssl"
require "tempfile"
require "tmpdir"

RSpec.describe Primus::Experiment::Runner do
  def blake_fixture_path
    "spec/fixtures/experiments/page_57_blake2b_valid.yml"
  end

  def blake_experiment
    Primus::Experiment.load(path: blake_fixture_path)
  end

  def changed_digest_experiment
    definition = Psych.safe_load(File.read(blake_fixture_path))
    definition.fetch("expectation")["digest"] = "0" * 128
    Tempfile.create(["page-57-changed-blake", ".yml"]) do |file|
      yield load_written_definition(file, definition)
    end
  end

  def load_written_definition(file, definition)
    file.write(Psych.dump(definition))
    file.flush
    Primus::Experiment.load(path: file.path)
  end

  describe "#run" do
    it "matches the independent page-57 BLAKE2b-512 digest" do
      Dir.mktmpdir do |output_path|
        runner = Primus::Experiment::Runner.new(experiment: blake_experiment,
                                                output_path: output_path)

        runner.run

        expect(runner.log_entry.data).to include(
          "status" => "matched", "comparison" => "match",
        )
      end
    end

    it "retains the exact 124 page-57 output bytes" do
      Dir.mktmpdir do |output_path|
        runner = Primus::Experiment::Runner.new(experiment: blake_experiment,
                                                output_path: output_path)
        expected = File.binread("experiments/expected/page-57-latin.txt")

        runner.run

        expect(runner.observation.output_bytes).to eq(expected)
      end
    end

    it "saves literal four-key BLAKE2b digest evidence" do
      Dir.mktmpdir do |output_path|
        runner = Primus::Experiment::Runner.new(experiment: blake_experiment,
                                                output_path: output_path)
        digest = "2e205b4c5686b98f55de31b2aac8151" \
                 "2ba7e034a7c2c11ddfb97fea2d57ef9d" \
                 "6a395367c2e98da2f86677e41713dc65" \
                 "d9d2af7e81eb8a54c749a1dd9fe844454"

        runner.run

        expect(runner.assessment.to_h.fetch("hash_check")).to eq(
          "algorithm" => "blake2b512",
          "policy" => "gp-latin-compatibility-v1",
          "expected_digest" => digest, "observed_digest" => digest
        )
      end
    end

    it "saves the BLAKE2b runtime descriptor with the attempt" do
      Dir.mktmpdir do |output_path|
        runner = Primus::Experiment::Runner.new(experiment: blake_experiment,
                                                output_path: output_path)

        runner.run

        expect(runner.log_entry.data.fetch("hash_runtime")).to include(
          "openssl_binding_version" => OpenSSL::VERSION,
          "openssl_build_version" => OpenSSL::OPENSSL_VERSION,
          "openssl_library_version" => OpenSSL::OPENSSL_LIBRARY_VERSION,
          "available" => true,
        )
      end
    end

    it "omits a dummy expected plaintext artifact" do
      Dir.mktmpdir do |output_path|
        runner = Primus::Experiment::Runner.new(experiment: blake_experiment,
                                                output_path: output_path)

        runner.run

        expect(runner.log_entry.data.fetch("artifacts")).not_to have_key(
          "expected.txt",
        )
      end
    end

    it "reuses an unchanged BLAKE2b attempt" do
      Dir.mktmpdir do |output_path|
        runner = Primus::Experiment::Runner.new(experiment: blake_experiment,
                                                output_path: output_path)
        runner.run
        first_id = runner.log_entry.run_id

        runner.run

        expect(runner.log_entry.run_id).to eq(first_id)
      end
    end

    it "links a reasoned BLAKE2b rerun to its prior attempt" do
      Dir.mktmpdir do |output_path|
        runner = Primus::Experiment::Runner.new(experiment: blake_experiment,
                                                output_path: output_path)
        runner.run
        first_id = runner.log_entry.run_id

        runner.run(rerun: true, reason: "Check independent digest again")

        expect(runner.log_entry.previous_run_ids).to eq([first_id])
      end
    end

    it "gives a changed BLAKE2b expectation a new attempt" do
      Dir.mktmpdir do |output_path|
        first = Primus::Experiment::Runner.new(experiment: blake_experiment,
                                               output_path: output_path)
        first.run

        changed_digest_experiment do |experiment|
          second = Primus::Experiment::Runner.new(experiment: experiment,
                                                  output_path: output_path)
          second.run

          expect(second.log_entry.run_id).not_to eq(first.log_entry.run_id)
        end
      end
    end

    it "records an unavailable digest as error rather than mismatch" do
      Dir.mktmpdir do |output_path|
        runner = Primus::Experiment::Runner.new(experiment: blake_experiment,
                                                output_path: output_path)
        allow(OpenSSL::Digest).to receive(:new).with("BLAKE2b512").
          and_raise(OpenSSL::Digest::DigestError,
                    "digest unavailable")

        begin
          runner.run
        rescue StandardError
          nil
        end

        expect(runner.log_entry.data).to include(
          "status" => "error", "comparison" => "not_checked",
          "assessment" => nil
        )
      end
    end

    it "retains the produced output when BLAKE2b is unavailable" do
      Dir.mktmpdir do |output_path|
        runner = Primus::Experiment::Runner.new(experiment: blake_experiment,
                                                output_path: output_path)
        expected = File.binread("experiments/expected/page-57-latin.txt")
        allow(OpenSSL::Digest).to receive(:new).with("BLAKE2b512").
          and_raise(OpenSSL::Digest::DigestError,
                    "digest unavailable")

        begin
          runner.run
        rescue StandardError
          nil
        end

        expect(runner.observation.output_bytes).to eq(expected)
      end
    end
  end
end
