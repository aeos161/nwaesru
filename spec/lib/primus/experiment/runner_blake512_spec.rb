require "tmpdir"

RSpec.describe Primus::Experiment::Runner do
  def blake512_experiment
    Primus::Experiment.load(
      path: "spec/fixtures/experiments/page_57_blake512_valid.yml",
    )
  end

  def runtime_descriptor
    { "backend" => "blake512-ruby", "available" => true,
      "schema_version" => 1, "algorithm" => "blake512",
      "gem_version" => "0.1.0", "upstream_revision" => "upstream-a",
      "source_sha256" => "a" * 64, "native_sha256" => "b" * 64,
      "ruby_engine" => "ruby", "ruby_api_version" => "2.7.0",
      "ruby_platform" => RUBY_PLATFORM, "dlext" => "bundle",
      "native_path" => "/tmp/native-a.bundle", "compiler" => "clang-a",
      "compile_flags" => "-O2" }
  end

  def unavailable_descriptor
    { "backend" => "blake512-ruby", "available" => false,
      "gem_version" => "0.1.0", "error_class" => "LoadError",
      "error_message" => "native load failed" }
  end

  def stub_backend(runtime:, digest: nil, error: nil)
    backend = instance_double(Primus::Experiment::Blake512, runtime: runtime)
    allow(backend).to receive(:hexdigest).and_return(digest) if digest
    allow(backend).to receive(:hexdigest).and_raise(error) if error
    allow(Primus::Experiment::Blake512).to receive(:new).and_return(backend)
  end

  def run_unavailable(runner)
    runner.run
  rescue Primus::Experiment::Blake512::Unavailable
    nil
  end

  def unavailable_failure
    Primus::Experiment::Blake512::Unavailable.new("native load failed")
  end

  def matching_backend(experiment)
    digest = experiment.expectation.fetch("digest")
    instance_double(Primus::Experiment::Blake512, hexdigest: digest)
  end

  describe "#run" do
    it "saves a match to the independent page-57 original BLAKE-512 oracle" do
      Dir.mktmpdir do |output_path|
        experiment = blake512_experiment
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        digest = "999826f07ba989ae4d25d57acfc5fb2b" \
                 "16102289d5bbc0a427cf2997a8ff89ac" \
                 "84bc545e6a8e06108794975fd88cb6dc" \
                 "7c7c64f967d4248b6d2a73cbb67cb3e7"

        runner.run

        expect(runner.assessment.to_h.fetch("hash_check")).to eq(
          "algorithm" => "blake512", "policy" => "gp-latin-compatibility-v1",
          "expected_digest" => digest, "observed_digest" => digest
        )
      end
    end

    it "saves the original BLAKE-512 runtime descriptor" do
      Dir.mktmpdir do |output_path|
        experiment = blake512_experiment
        runtime = runtime_descriptor
        digest = experiment.expectation.fetch("digest")
        stub_backend(runtime: runtime, digest: digest)
        runner = Primus::Experiment::Runner.new(
          experiment: experiment, output_path: output_path,
        )

        runner.run

        expect(runner.log_entry.data.fetch("hash_runtime")).to eq(runtime)
      end
    end

    it "reuses an attempt when only backend diagnostics change" do
      Dir.mktmpdir do |output_path|
        experiment = blake512_experiment
        backend = matching_backend(experiment)
        allow(backend).to receive(:runtime).and_return(
          runtime_descriptor,
          runtime_descriptor.merge("native_path" => "/tmp/native-b.bundle",
                                   "compiler" => "clang-b",
                                   "compile_flags" => "-g"),
        )
        allow(Primus::Experiment::Blake512).to receive(:new).and_return(backend)
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        runner.run
        first_id = runner.log_entry.run_id

        runner.run

        expect(runner.log_entry.run_id).to eq(first_id)
      end
    end

    it "creates another attempt when the native artifact changes" do
      Dir.mktmpdir do |output_path|
        experiment = blake512_experiment
        backend = matching_backend(experiment)
        allow(backend).to receive(:runtime).and_return(
          runtime_descriptor,
          runtime_descriptor.merge("native_sha256" => "c" * 64),
        )
        allow(Primus::Experiment::Blake512).to receive(:new).and_return(backend)
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        runner.run
        first_id = runner.log_entry.run_id

        runner.run

        expect(runner.log_entry.run_id).not_to eq(first_id)
      end
    end

    it "creates another attempt when the gem source changes" do
      Dir.mktmpdir do |output_path|
        experiment = blake512_experiment
        backend = matching_backend(experiment)
        allow(backend).to receive(:runtime).and_return(
          runtime_descriptor,
          runtime_descriptor.merge("source_sha256" => "c" * 64),
        )
        allow(Primus::Experiment::Blake512).to receive(:new).and_return(backend)
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        runner.run
        first_id = runner.log_entry.run_id

        runner.run

        expect(runner.log_entry.run_id).not_to eq(first_id)
      end
    end

    it "creates a new attempt when backend availability is restored" do
      Dir.mktmpdir do |output_path|
        experiment = blake512_experiment
        digest = experiment.expectation.fetch("digest")
        backend = instance_double(Primus::Experiment::Blake512)
        allow(backend).to receive(:runtime).and_return(unavailable_descriptor)
        allow(backend).to receive(:hexdigest).and_raise(unavailable_failure)
        allow(Primus::Experiment::Blake512).to receive(:new).and_return(backend)
        runner = Primus::Experiment::Runner.new(experiment: experiment,
                                                output_path: output_path)
        run_unavailable(runner)
        first_id = runner.log_entry.run_id
        allow(backend).to receive(:runtime).and_return(runtime_descriptor)
        allow(backend).to receive(:hexdigest).and_return(digest)

        runner.run

        expect(runner.log_entry.run_id).not_to eq(first_id)
      end
    end

    it "saves backend unavailability as error and not_checked" do
      Dir.mktmpdir do |output_path|
        unavailable = unavailable_descriptor
        failure = unavailable_failure
        stub_backend(runtime: unavailable, error: failure)
        runner = Primus::Experiment::Runner.new(experiment: blake512_experiment,
                                                output_path: output_path)

        run_unavailable(runner)

        expect(runner.log_entry.data).to include(
          "status" => "error", "comparison" => "not_checked",
          "assessment" => nil
        )
      end
    end

    it "retains produced observation bytes after backend unavailability" do
      Dir.mktmpdir do |output_path|
        unavailable = unavailable_descriptor
        failure = unavailable_failure
        stub_backend(runtime: unavailable, error: failure)
        runner = Primus::Experiment::Runner.new(experiment: blake512_experiment,
                                                output_path: output_path)
        expected = File.binread("experiments/expected/page-57-latin.txt")

        run_unavailable(runner)

        expect(runner.observation.output_bytes).to eq(expected)
      end
    end
  end
end
