require "open3"
require "rbconfig"
require "tmpdir"

RSpec.describe Primus::Commands::Experiments do
  def in_clean_checkout
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      yield repository, File.join(directory, "runs")
    end
  end

  def clone_repository(repository)
    _output, error, status = Open3.capture3(
      "git", "clone", "--quiet", "--local", "--no-hardlinks", Dir.pwd,
      repository
    )
    raise "Test repository clone failed: #{error}" unless status.success?
  end

  def cli(repository, *arguments)
    Open3.capture3(RbConfig.ruby, "-Ilib", "bin/primus", "experiments",
                   *arguments, chdir: repository)
  end

  describe "#validate" do
    it "accepts the saved original BLAKE-512 control" do
      in_clean_checkout do |repository, _output_path|
        _stdout, _stderr, status = cli(repository, "validate",
                                       "page-57-latin-blake512")

        expect(status).to be_success
      end
    end

    it "labels the original BLAKE-512 digest explicitly" do
      in_clean_checkout do |repository, _output_path|
        stdout, _stderr, _status = cli(repository, "validate",
                                       "page-57-latin-blake512")

        expect(stdout).to include("hash algorithm: blake512",
                                  "expected BLAKE-512:")
      end
    end
  end

  describe "#execute" do
    it "runs the saved original BLAKE-512 page-57 control to a match" do
      in_clean_checkout do |repository, output_path|
        stdout, _stderr, _status = cli(repository, "run",
                                       "page-57-latin-blake512",
                                       "--output-path", output_path)

        expect(stdout).to include("matched (match)")
      end
    end
  end

  describe "#review" do
    it "shows the saved original BLAKE-512 assessment" do
      in_clean_checkout do |repository, output_path|
        cli(repository, "run", "page-57-latin-blake512", "--output-path",
            output_path)

        stdout, _stderr, _status = cli(repository, "review",
                                       "page-57-latin-blake512",
                                       "--output-path", output_path)

        expect(stdout).to include("observed BLAKE-512:",
                                  "comparison: match")
      end
    end
  end
end
