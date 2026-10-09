require "json"
require "open3"
require "tmpdir"

RSpec.describe "saved output analysis lifecycle" do
  def completed_observation(root)
    experiment = Primus::Experiment.load(
      path: "spec/fixtures/experiments/page_57_valid.yml",
    )
    producer = Primus::Experiment::Runner.new(experiment: experiment,
                                              output_path: root)
    producer.run
    producer.log_entry.run_id
  end

  def analysis_definition(directory, representations: %w[gp-runes-v1 gp-expanded-latin-v1])
    declarations = representations.each_with_index.map do |representation, index|
      { "id" => "statistics-#{index + 1}", "analyzer" => "symbol-statistics",
        "version" => 1, "target" => { "stage" => "final",
                                     "representation" => representation } }
    end
    path = File.join(directory, "analysis.yml")
    File.write(path, Psych.dump("schema_version" => 1,
                                "id" => "final-symbol-statistics",
                                "analyses" => declarations))
    path
  end

  def command(*arguments)
    Open3.capture3("bin/primus", "analyses", *arguments)
  end

  describe "analyses run" do
    it "prints separate final GP and expanded Latin measurements" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        run_id = completed_observation(root)
        definition = analysis_definition(directory)

        stdout, _stderr, status = command("run", "page-57-latin", run_id,
                                          "--definition", definition,
                                          "--output-path", root)

        expect([status.success?, stdout]).to match([true, a_string_including(
          "statistics-1", "gp-runes-v1", "statistics-2",
          "gp-expanded-latin-v1", "raw IC",
        )])
      end
    end

    it "appends analysis without changing the saved observation record" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        run_id = completed_observation(root)
        definition = analysis_definition(directory)
        record = File.join(root, "page-57-latin", run_id, "record.json")
        original = File.binread(record)

        _stdout, _stderr, status = command("run", "page-57-latin", run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, File.binread(record)]).to eq([true, original])
      end
    end

    it "creates distinct additive analysis records on repeat execution" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        run_id = completed_observation(root)
        definition = analysis_definition(directory)
        args = ["run", "page-57-latin", run_id, "--definition", definition,
                "--output-path", root]

        command(*args)
        command(*args)

        expect(Dir.glob(File.join(root, "page-57-latin", run_id,
                                  "analyses", "*", "record.json")).size).to eq(2)
      end
    end
  end

  describe "analyses review" do
    it "reviews retained measurements after the definition is removed" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        run_id = completed_observation(root)
        definition = analysis_definition(directory)
        command("run", "page-57-latin", run_id,
                "--definition", definition, "--output-path", root)
        File.delete(definition)

        stdout, _stderr, status = command("review", "page-57-latin", run_id,
                                          "--output-path", root)

        expect([status.success?, stdout]).to match([true, a_string_including(
          "gp-runes-v1", "gp-expanded-latin-v1", "raw IC",
        )])
      end
    end
  end
end
