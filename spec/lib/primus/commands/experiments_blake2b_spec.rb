require "fileutils"
require "open3"
require "rbconfig"
require "tmpdir"

RSpec.describe Primus::Commands::Experiments do
  def with_blake_checkout
    Dir.mktmpdir do |directory|
      repository = prepare_checkout(directory)
      yield repository, File.join(directory, "runs")
    end
  end

  def prepare_checkout(directory)
    repository = File.join(directory, "repo")
    clone_repository(repository)
    install_blake_definition(repository)
    repository
  end

  def clone_repository(repository)
    _out, error, status = Open3.capture3(
      "git", "clone", "--quiet", "--local", "--no-hardlinks", Dir.pwd,
      repository
    )
    raise "Test repository clone failed: #{error}" unless status.success?
  end

  def install_blake_definition(repository)
    source = File.join(repository, "spec/fixtures/experiments",
                       "page_57_blake2b_valid.yml")
    destination = File.join(repository, "experiments/definitions",
                            "page-57-latin-blake2b512.yml")
    FileUtils.cp(source, destination)
  end

  def cli(repository, *arguments)
    Open3.capture3(RbConfig.ruby, "-Ilib", "bin/primus", "experiments",
                   *arguments, chdir: repository)
  end

  describe "#validate" do
    it "accepts the BLAKE2b-512 control by its distinct ID" do
      with_blake_checkout do |repository, _output_path|
        _stdout, _stderr, status = cli(repository, "validate",
                                       "page-57-latin-blake2b512")

        expect(status).to be_success
      end
    end

    it "shows the fixed expected BLAKE2b-512 digest" do
      with_blake_checkout do |repository, _output_path|
        stdout, _stderr, _status = cli(repository, "validate",
                                       "page-57-latin-blake2b512")
        digest = "2e205b4c5686b98f55de31b2aac8151" \
                 "2ba7e034a7c2c11ddfb97fea2d57ef9d" \
                 "6a395367c2e98da2f86677e41713dc65" \
                 "d9d2af7e81eb8a54c749a1dd9fe844454"

        expect(stdout).to include("hash algorithm: blake2b512", digest)
      end
    end
  end

  describe "#execute" do
    it "runs the real BLAKE2b control to a match" do
      with_blake_checkout do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "run",
                                       "page-57-latin-blake2b512",
                                       "--output-path", output_path)

        expect(stdout).to include("matched (match)")
      end
    end
  end

  describe "#review" do
    it "shows saved BLAKE2b evidence after the definition is removed" do
      with_blake_checkout do |repository, output_path|
        cli(repository, "run", "page-57-latin-blake2b512",
            "--output-path", output_path)
        File.delete(File.join(repository, "experiments/definitions",
                              "page-57-latin-blake2b512.yml"))

        stdout, _stderr, _status = cli(repository, "review",
                                       "page-57-latin-blake2b512",
                                       "--output-path", output_path)

        expect(stdout).to include("hash algorithm: blake2b512",
                                  "gp-latin-compatibility-v1",
                                  "comparison: match")
      end
    end
  end
end
