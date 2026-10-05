require "fileutils"
require "open3"
require "rbconfig"
require "tmpdir"

RSpec.describe Primus::Commands::Experiments do
  def with_hash_checkout
    Dir.mktmpdir do |directory|
      repository = prepare_checkout(directory)
      yield repository, File.join(directory, "runs")
    end
  end

  def prepare_checkout(directory)
    repository = File.join(directory, "repo")
    clone_repository(repository)
    install_hash_definition(repository)
    repository
  end

  def clone_repository(repository)
    _out, error, status = Open3.capture3(
      "git", "clone", "--quiet", "--local", "--no-hardlinks", Dir.pwd,
      repository
    )
    raise "Test repository clone failed: #{error}" unless status.success?
  end

  def install_hash_definition(repository)
    source = File.join(repository, "spec/fixtures/experiments",
                       "page_57_hash_valid.yml")
    destination = File.join(repository, "experiments/definitions",
                            "page-57-latin-sha512.yml")
    FileUtils.cp(source, destination)
  end

  def cli(repository, *arguments)
    Open3.capture3(RbConfig.ruby, "-Ilib", "bin/primus", "experiments",
                   *arguments, chdir: repository)
  end

  describe "#validate" do
    it "accepts the hash experiment by its distinct ID" do
      with_hash_checkout do |repository, _output_path|
        _out, _err, status = cli(repository, "validate",
                                 "page-57-latin-sha512")

        expect(status).to be_success
      end
    end

    it "labels the fixed SHA-512 digest and compatibility policy" do
      with_hash_checkout do |repository, _output_path|
        stdout, _err, _status = cli(repository, "validate",
                                    "page-57-latin-sha512")
        digest = "f3fac0115ab06d1a4075731e77fe157" \
                 "ad52b837b9068bf942c95784160578f4" \
                 "3a1a72e770f2e2c1b00a1bc2fad39dc6" \
                 "6fa78efd28c5cd976ed3a35f3e400bcab"

        expect(stdout).to include("SHA-512", digest,
                                  "gp-latin-compatibility-v1")
      end
    end

    it "labels only the input SHA-256 identity during hash validation" do
      with_hash_checkout do |repository, _output_path|
        stdout, _err, _status = cli(repository, "validate",
                                    "page-57-latin-sha512")

        source_digest = "c7055db0173e43eb231608812f5d5256" \
                        "9e4c0817934b1a65427cebf332759fff"

        expect(stdout.lines.grep(/SHA-256:/)).to eq(
          ["input SHA-256: #{source_digest}\n"],
        )
      end
    end
  end

  describe "#execute" do
    it "runs the hash experiment by ID" do
      with_hash_checkout do |repository, output_path|
        stdout, _err, _status = cli(repository, "run",
                                    "page-57-latin-sha512", "--output-path",
                                    output_path)

        expect(stdout).to include("matched (match)")
      end
    end
  end

  describe "#review" do
    it "shows the saved scientific SHA-512 comparison" do
      with_hash_checkout do |repository, output_path|
        cli(repository, "run", "page-57-latin-sha512", "--output-path",
            output_path)

        stdout, _err, _status = cli(repository, "review",
                                    "page-57-latin-sha512", "--output-path",
                                    output_path)

        expect(stdout).to include("SHA-512", "gp-latin-compatibility-v1",
                                  "match")
      end
    end

    it "shows the fixed expected digest for a planned hash experiment" do
      with_hash_checkout do |repository, output_path|
        stdout, _err, _status = cli(repository, "review",
                                    "page-57-latin-sha512", "--output-path",
                                    output_path)

        digest = "f3fac0115ab06d1a4075731e77fe157" \
                 "ad52b837b9068bf942c95784160578f4" \
                 "3a1a72e770f2e2c1b00a1bc2fad39dc6" \
                 "6fa78efd28c5cd976ed3a35f3e400bcab"

        expect(stdout).to include(digest)
      end
    end
  end
end
