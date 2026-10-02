require "digest"
require "json"
require "open3"
require "rbconfig"
require "tmpdir"

RSpec.describe "page 57 execution identity" do
  def clone_repository(path)
    _stdout, stderr, status = Open3.capture3(
      "git", "clone", "--quiet", "--local", "--no-hardlinks", Dir.pwd, path
    )
    raise "Test repository clone failed: #{stderr}" unless status.success?
  end

  def run_experiment(repository, output_path)
    Open3.capture3(
      RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "run",
      "page-57-latin",
      "--output-path", output_path, chdir: repository
    )
  end

  def rerun_experiment(repository, output_path)
    args = [
      RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "run",
      "page-57-latin",
      "--output-path", output_path, "--rerun", "--reason", "Investigate stop"
    ]
    Open3.capture3(*args, chdir: repository)
  end

  def annotate_page_57_source(repository)
    source = File.join(repository, "data/encoded/liber_primus/page_57.yml")
    original = File.binread(source)
    changed = "#{original}# test-only source annotation\n"
    File.binwrite(source, changed)
    [original, changed]
  end

  def update_definition_digest(repository, original, changed)
    definition = File.join(repository,
                           "experiments/definitions/page-57-latin.yml")
    old_digest = Digest::SHA256.hexdigest(original)
    new_digest = Digest::SHA256.hexdigest(changed)
    File.write(definition, File.read(definition).sub(old_digest, new_digest))
  end

  def replace_page_57_source(repository, changed)
    source = File.join(repository, "data/encoded/liber_primus/page_57.yml")
    original = File.binread(source)
    File.binwrite(source, changed)
    update_definition_digest(repository, original, changed)
  end

  def append_unrelated_readme_change(repository)
    File.open(File.join(repository, "README.md"), "a") do |file|
      file.write("\nTest-only unrelated change.\n")
    end
  end

  def commit_tracked_change(repository)
    args = ["git", "-C", repository, "-c", "user.name=Spec",
            "-c", "user.email=spec@example.invalid",
            "-c", "commit.gpgsign=false", "commit", "-am",
            "test fixture code change"]
    _stdout, stderr, status = Open3.capture3(*args)
    raise "Test repository commit failed: #{stderr}" unless status.success?
  end

  def make_translator_raise(repository, error_name)
    path = File.join(repository, "lib/primus.rb")
    injected = [
      "\nPrimus::Document::Translator.prepend(Module.new do",
      "  def visit_token(token); raise #{error_name}; end",
      "end)\n",
    ].join("\n")
    File.open(path, "a") { |file| file.write("\n#{injected}") }
  end

  def change_source_after_validation(repository)
    path = File.join(repository, "lib/primus.rb")
    injected = <<~RUBY
      Primus::Experiment.prepend(Module.new do
        def valid?(*args)
          result = super
          File.binwrite("data/encoded/liber_primus/page_57.yml",
                        "body: 'ᚠ'") if result
          result
        end
      end)
    RUBY
    File.open(path, "a") { |file| file.write("\n#{injected}") }
  end

  def saved_records(output_path)
    Dir.glob("#{output_path}/**/record.json").map do |path|
      JSON.parse(File.read(path))
    end
  end

  def saved_statuses(output_path)
    saved_records(output_path).map { |record| record.fetch("status") }
  end

  def saved_stages(output_path)
    saved_records(output_path).flat_map do |record|
      record.fetch("errors").map { |error| error.fetch("stage") }
    end
  end

  def saved_input_snapshots(output_path)
    saved_records(output_path).map do |record|
      path = record.fetch("artifacts").dig("input.yml", "path")
      path && File.binread(path)
    end
  end

  it "rejects modified executable code before transformation" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      File.open(File.join(repository, "lib/primus.rb"), "a") do |file|
        file.write("\n# test-only dirty code\n")
      end
      output_path = File.join(directory, "runs")

      run_experiment(repository, output_path)

      expect(saved_stages(output_path)).to include("code")
    end
  end

  it "keeps standalone validation read-only" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)

      Open3.capture3(
        RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "validate",
        "page-57-latin", chdir: repository
      )

      expect(Dir.glob("#{repository}/experiments/runs/**/record.json")).
        to be_empty
    end
  end

  it "rejects an untracked executable file" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      File.write(File.join(repository, "lib/untracked_test_code.rb"), "# new")
      output_path = File.join(directory, "runs")

      run_experiment(repository, output_path)

      expect(saved_stages(output_path)).to include("code")
    end
  end

  it "runs again after the source bytes and declared digest change" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      output_path = File.join(directory, "runs")
      run_experiment(repository, output_path)
      original, changed = annotate_page_57_source(repository)
      update_definition_digest(repository, original, changed)

      run_experiment(repository, output_path)

      expect(saved_statuses(output_path)).to eq(["matched", "matched"])
    end
  end

  it "revalidates source bytes after an earlier validation" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      definition = "page-57-latin"
      Open3.capture3(
        RbConfig.ruby, "-Ilib", "bin/primus", "experiments", "validate",
        definition, chdir: repository
      )
      annotate_page_57_source(repository)
      output_path = File.join(directory, "runs")

      run_experiment(repository, output_path)

      expect(saved_stages(output_path)).to include("integrity")
    end
  end

  it "runs again after Git HEAD changes" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      output_path = File.join(directory, "runs")
      run_experiment(repository, output_path)
      append_unrelated_readme_change(repository)
      commit_tracked_change(repository)

      run_experiment(repository, output_path)

      expect(saved_statuses(output_path)).to eq(["matched", "matched"])
    end
  end

  it "reuses a prior attempt after a YAML-only formatting change" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      output_path = File.join(directory, "runs")
      run_experiment(repository, output_path)
      definition = File.join(repository,
                             "experiments/definitions/page-57-latin.yml")
      File.open(definition, "a") { |file| file.write("\n# formatting only\n") }

      run_experiment(repository, output_path)

      expect(Dir.glob("#{output_path}/**/record.json").size).to eq(1)
    end
  end

  it "runs again after a parsed definition field changes" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      output_path = File.join(directory, "runs")
      run_experiment(repository, output_path)
      definition = File.join(repository,
                             "experiments/definitions/page-57-latin.yml")
      original = File.read(definition)
      File.write(definition, original.sub("Compare the direct",
                                          "Recheck the direct"))

      run_experiment(repository, output_path)

      expect(saved_statuses(output_path)).to eq(["matched", "matched"])
    end
  end

  it "rejects malformed encoded source YAML before transformation" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      replace_page_57_source(repository, "---\nbody: [ᛈ\n")
      output_path = File.join(directory, "runs")

      run_experiment(repository, output_path)

      expect(saved_stages(output_path)).to include("configuration")
    end
  end

  it "rejects a nonstring encoded source body" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      replace_page_57_source(repository, "---\nbody: [ᛈ]\n")
      output_path = File.join(directory, "runs")

      run_experiment(repository, output_path)

      expect(saved_stages(output_path)).to include("configuration")
    end
  end

  it "rejects a source body without page 57 runes" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      replace_page_57_source(repository, "---\nbody: abc\n")
      output_path = File.join(directory, "runs")

      run_experiment(repository, output_path)

      expect(saved_stages(output_path)).to include("configuration")
    end
  end

  it "rejects invalid UTF-8 encoded source bytes" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      replace_page_57_source(repository, "---\nbody: \xff\n".b)
      output_path = File.join(directory, "runs")

      run_experiment(repository, output_path)

      expect(saved_stages(output_path)).to include("configuration")
    end
  end

  it "identifies a missing encoded source file" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      source = File.join(repository, "data/encoded/liber_primus/page_57.yml")
      File.delete(source)
      output_path = File.join(directory, "runs")

      run_experiment(repository, output_path)

      expect(saved_stages(output_path)).to include("configuration")
    end
  end

  it "records an execution error without a false mismatch" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      make_translator_raise(repository, '"test-only translation failure"')
      commit_tracked_change(repository)
      output_path = File.join(directory, "runs")

      run_experiment(repository, output_path)
      records = saved_records(output_path)
      statuses = records.map { |record| record["status"] }

      expect(statuses).to eq(["error"])
    end
  end

  it "leaves an interrupted attempt visibly running" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      make_translator_raise(repository, "Interrupt")
      commit_tracked_change(repository)
      output_path = File.join(directory, "runs")

      run_experiment(repository, output_path)
      records = Dir.glob("#{output_path}/**/record.json").map do |path|
        JSON.parse(File.read(path))
      end
      statuses = records.map { |record| record["status"] }

      expect(statuses).to eq(["running"])
    end
  end

  it "reuses an execution error instead of losing the failed attempt" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      make_translator_raise(repository, '"test-only translation failure"')
      commit_tracked_change(repository)
      output_path = File.join(directory, "runs")
      run_experiment(repository, output_path)

      run_experiment(repository, output_path)

      expect(Dir.glob("#{output_path}/**/record.json").size).to eq(1)
    end
  end

  it "records the reason and history for an intentional interrupted rerun" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      make_translator_raise(repository, "Interrupt")
      commit_tracked_change(repository)
      output_path = File.join(directory, "runs")
      run_experiment(repository, output_path)
      run_experiment(repository, output_path)

      rerun_experiment(repository, output_path)
      records = saved_records(output_path)

      expect(records.count { |record|
        record["rerun_reason"] == "Investigate stop"
      }).to eq(1)
    end
  end

  it "runs and saves the exact input bytes validated for that attempt" do
    Dir.mktmpdir do |directory|
      repository = File.join(directory, "repo")
      clone_repository(repository)
      source = File.join(repository, "data/encoded/liber_primus/page_57.yml")
      original = File.binread(source)
      change_source_after_validation(repository)
      commit_tracked_change(repository)
      output_path = File.join(directory, "runs")

      run_experiment(repository, output_path)
      snapshots = saved_input_snapshots(output_path)

      expect(snapshots).to eq([original])
    end
  end
end
