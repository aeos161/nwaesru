require "json"
require "digest"
require "fileutils"
require "open3"
require "tmpdir"

RSpec.describe "saved output analysis lifecycle" do
  include SavedAnalysisHelper

  def completed_observation(root)
    experiment = Primus::Experiment.load(
      path: "spec/fixtures/experiments/page_57_checkpoints.yml",
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

  def observation_record(root, run_id, id: "page-57-latin")
    path = File.join(root, id, run_id, "record.json")
    [path, JSON.parse(File.binread(path))]
  end

  def replace_provenance(root, id, run_id, rows)
    path, record = observation_record(root, run_id, id: id)
    artifact = record.fetch("artifacts").fetch("provenance.json")
    bytes = JSON.pretty_generate(rows)
    File.binwrite(artifact.fetch("path"), bytes)
    artifact["bytes"] = bytes.bytesize
    artifact["sha256"] = Digest::SHA256.hexdigest(bytes)
    record.fetch("observation").fetch("representations").each_value do |profile|
      profile["provenance_sha256"] = artifact.fetch("sha256")
    end
    File.write(path, JSON.pretty_generate(record))
  end

  describe "analyses run" do
    it "retains the independently specified rune and expanded-Latin IC ratios" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)

        command("run", id, run_id, "--definition", definition,
                "--output-path", root)
        record_path = Dir.glob(File.join(root, id, run_id, "analyses", "*",
                                         "record.json")).fetch(0)
        results = JSON.parse(File.binread(record_path)).fetch("results")

        expect(results.map { |entry| entry.fetch("result").fetch("ic").values_at(
          "numerator", "denominator", "value",
        ) }).to eq([[2, 6, (1.0 / 3)], [4, 20, (1.0 / 5)]])
      end
    end

    it "persists the existing analysis record fields" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)

        command("run", id, run_id, "--definition", definition,
                "--output-path", root)
        record_path = Dir.glob(File.join(root, id, run_id, "analyses", "*",
                                         "record.json")).fetch(0)
        record = JSON.parse(File.binread(record_path))

        expect(record.keys).to include(
          "schema_version", "experiment_id", "run_id", "analysis_run_id",
          "status", "started_at", "completed_at", "definition_sha256",
          "definition", "observation_record_sha256", "observation_output",
          "observation_provenance", "representations", "output_policy",
          "git_head", "code_clean", "ruby_version", "results", "errors",
        )
      end
    end

    it "persists result envelopes in declaration order" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)

        command("run", id, run_id, "--definition", definition,
                "--output-path", root)
        record_path = Dir.glob(File.join(root, id, run_id, "analyses", "*",
                                         "record.json")).fetch(0)
        results = JSON.parse(File.binread(record_path)).fetch("results")

        expect(results.map { |entry| entry.values_at("declaration_id", "analyzer",
                                                     "version", "stage", "representation",
                                                     "exclusions") }).to eq([
          ["statistics-1", "symbol-statistics", 1, "final", "gp-runes-v1",
           "non-GP passthrough literals"],
          ["statistics-2", "symbol-statistics", 1, "final", "gp-expanded-latin-v1",
           "non-GP passthrough literals"],
        ])
      end
    end

    it "prints both retained raw IC ratios for the tiny final output" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)

        stdout, _stderr, _status = command("run", id, run_id,
                                            "--definition", definition,
                                            "--output-path", root)
        ic_lines = stdout.lines.map(&:strip).select { |line| line.start_with?("raw IC:") }

        expect(ic_lines).to eq(["raw IC: computed 2/6 0.3333333333333333",
                                "raw IC: computed 4/20 0.2"])
      end
    end

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

    it "creates distinct analysis records for simultaneous invocations" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)
        arguments = ["run", id, run_id, "--definition", definition,
                     "--output-path", root]

        statuses = Array.new(2) { Thread.new { command(*arguments).last } }.
                   map { |thread| thread.value.success? }
        records = Dir.glob(File.join(root, id, run_id, "analyses", "*",
                                     "record.json"))

        expect([statuses, records.size]).to eq([[true, true], 2])
      end
    end

    it "reports an analysis persistence failure as an execution error" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)
        File.write(File.join(root, id, run_id, "analyses"), "not a directory")

        _stdout, stderr, status = command("run", id, run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /persist|write|director|file exists/i])
      end
    end

    it "rejects duplicate analysis declaration IDs before reserving a result" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        run_id = completed_observation(root)
        definition = analysis_definition(directory)
        data = Psych.safe_load(File.binread(definition))
        data.fetch("analyses")[1]["id"] = "statistics-1"
        File.write(definition, Psych.dump(data))

        _stdout, stderr, status = command("run", "page-57-latin", run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        records = Dir.glob(File.join(root, "page-57-latin", run_id,
                                     "analyses", "*", "record.json"))

        expect([status.success?, stderr, records]).to match([false, /duplicate.*id/i, []])
      end
    end

    it "rejects a repeated representation before reserving a result" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        run_id = completed_observation(root)
        definition = analysis_definition(directory,
                                         representations: %w[gp-runes-v1 gp-runes-v1])

        _stdout, stderr, status = command("run", "page-57-latin", run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        records = Dir.glob(File.join(root, "page-57-latin", run_id,
                                     "analyses", "*", "record.json"))

        expect([status.success?, stderr, records]).to match([false, /representation/i, []])
      end
    end

    it "rejects an unsupported stage" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        run_id = completed_observation(root)
        definition = analysis_definition(directory)
        data = Psych.safe_load(File.binread(definition))
        data.fetch("analyses").first.fetch("target")["stage"] = "input"
        File.write(definition, Psych.dump(data))

        _stdout, stderr, status = command("run", "page-57-latin", run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /stage/i])
      end
    end

    it "rejects unknown definition keys" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        run_id = completed_observation(root)
        definition = analysis_definition(directory)
        data = Psych.safe_load(File.binread(definition))
        data["threshold"] = 0.1
        File.write(definition, Psych.dump(data))

        _stdout, stderr, status = command("run", "page-57-latin", run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /threshold/])
      end
    end

    it "rejects duplicate YAML keys rather than accepting the last value" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        run_id = completed_observation(root)
        definition = analysis_definition(directory)
        File.open(definition, "a") { |file| file.write("id: replaced\n") }

        _stdout, stderr, status = command("run", "page-57-latin", run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /duplicate.*id/i])
      end
    end

    it "rejects missing explicit run identity" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        definition = analysis_definition(directory)

        _stdout, stderr, status = command("run", "page-57-latin",
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /run.*id/i])
      end
    end

    it "rejects an observation without the final representation manifest" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        run_id = completed_observation(root)
        definition = analysis_definition(directory)
        path, record = observation_record(root, run_id)
        record.fetch("observation").delete("representations")
        File.write(path, JSON.pretty_generate(record))

        _stdout, stderr, status = command("run", "page-57-latin", run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /recreat|manifest/i])
      end
    end

    it "rejects changed output bytes before producing a result" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        run_id = completed_observation(root)
        definition = analysis_definition(directory)
        _path, record = observation_record(root, run_id)
        output = record.fetch("artifacts").fetch("output.txt").fetch("path")
        File.open(output, "ab") { |file| file.write("changed") }

        command("run", "page-57-latin", run_id,
                "--definition", definition, "--output-path", root)
        records = Dir.glob(File.join(root, "page-57-latin", run_id,
                                     "analyses", "*", "record.json"))

        expect(records).to be_empty
      end
    end

    it "rejects artifact paths escaping the selected run" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        run_id = completed_observation(root)
        definition = analysis_definition(directory)
        path, record = observation_record(root, run_id)
        output = record.fetch("artifacts").fetch("output.txt")
        escaped = File.join(directory, "outside.txt")
        File.binwrite(escaped, File.binread(output.fetch("path")))
        output["path"] = escaped
        File.write(path, JSON.pretty_generate(record))

        _stdout, stderr, status = command("run", "page-57-latin", run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /output.*path|escap|outside/i])
      end
    end

    it "rejects reordered provenance even when checksums are updated" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        run_id = completed_observation(root)
        definition = analysis_definition(directory)
        path, record = observation_record(root, run_id)
        artifact = record.fetch("artifacts").fetch("provenance.json")
        rows = JSON.parse(File.binread(artifact.fetch("path")))
        rows[1]["ordinal"] = 0
        bytes = JSON.pretty_generate(rows)
        File.binwrite(artifact.fetch("path"), bytes)
        artifact["bytes"] = bytes.bytesize
        artifact["sha256"] = Digest::SHA256.hexdigest(bytes)
        record.fetch("observation").fetch("representations").each_value do |profile|
          profile["provenance_sha256"] = artifact.fetch("sha256")
        end
        File.write(path, JSON.pretty_generate(record))

        _stdout, stderr, status = command("run", "page-57-latin", run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /ordinal/i])
      end
    end

    it "runs a single Latin declaration without creating a rune result" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory,
                                         representations: ["gp-expanded-latin-v1"])

        command("run", id, run_id, "--definition", definition,
                "--output-path", root)
        record_path = Dir.glob(File.join(root, id, run_id, "analyses", "*",
                                         "record.json")).fetch(0)
        results = JSON.parse(File.binread(record_path)).fetch("results")

        expect(results.map { |entry| entry.fetch("representation") }).to eq(
          ["gp-expanded-latin-v1"],
        )
      end
    end

    it "retains declaration order when Latin precedes runes" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory,
                                         representations: %w[gp-expanded-latin-v1 gp-runes-v1])

        command("run", id, run_id, "--definition", definition,
                "--output-path", root)
        record_path = Dir.glob(File.join(root, id, run_id, "analyses", "*",
                                         "record.json")).fetch(0)
        results = JSON.parse(File.binread(record_path)).fetch("results")

        expect(results.map { |entry| entry.fetch("representation") }).to eq(
          %w[gp-expanded-latin-v1 gp-runes-v1],
        )
      end
    end

    it "retains an empty synthetic observation with insufficient IC" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root,
                                                         runes: [], letters: [],
                                                         output: "")
        definition = analysis_definition(directory)

        command("run", id, run_id, "--definition", definition,
                "--output-path", root)
        record_path = Dir.glob(File.join(root, id, run_id, "analyses", "*",
                                         "record.json")).fetch(0)
        results = JSON.parse(File.binread(record_path)).fetch("results")

        expect(results.map { |entry| entry.fetch("result").fetch("ic") }).to all(
          include("status" => "insufficient_sample", "numerator" => 0,
                  "denominator" => 0, "value" => nil),
        )
      end
    end

    it "measures an intact final output after a historical hash error" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)
        path, record = observation_record(root, run_id, id: id)
        record["status"] = "error"
        record["comparison"] = "not_checked"
        record["errors"] = [{ "stage" => "assessment", "message" => "backend unavailable" }]
        File.write(path, JSON.pretty_generate(record))

        _stdout, _stderr, status = command("run", id, run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect(status).to be_success
      end
    end

    it "rejects an unfinished observation" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)
        path, record = observation_record(root, run_id, id: id)
        record["status"] = "running"
        record["completed_at"] = nil
        File.write(path, JSON.pretty_generate(record))

        _stdout, stderr, status = command("run", id, run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /running|unfinished|incomplete/i])
      end
    end

    it "rejects a saved Latin expansion that contradicts the canonical map" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)
        _path, record = observation_record(root, run_id, id: id)
        provenance_path = record.fetch("artifacts").fetch("provenance.json").fetch("path")
        rows = JSON.parse(File.binread(provenance_path))
        rows.first["latin"] = "ing"
        replace_provenance(root, id, run_id, rows)

        _stdout, stderr, status = command("run", id, run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /latin|expansion/i])
      end
    end

    it "rejects repeated original source identities after checksum repair" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)
        _path, record = observation_record(root, run_id, id: id)
        provenance_path = record.fetch("artifacts").fetch("provenance.json").fetch("path")
        rows = JSON.parse(File.binread(provenance_path))
        rows[1]["rune_index"] = 0
        replace_provenance(root, id, run_id, rows)

        _stdout, stderr, status = command("run", id, run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /source|identity|rune_index/i])
      end
    end

    it "rejects a decoded symbol outside the declared GP alphabet" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)
        _path, record = observation_record(root, run_id, id: id)
        provenance_path = record.fetch("artifacts").fetch("provenance.json").fetch("path")
        rows = JSON.parse(File.binread(provenance_path))
        rows.first["decoded_rune"] = "?"
        replace_provenance(root, id, run_id, rows)

        _stdout, stderr, status = command("run", id, run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /decoded|symbol|alphabet/i])
      end
    end

    it "rejects an unsupported saved output policy" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)
        path, record = observation_record(root, run_id, id: id)
        record.fetch("configuration").fetch("output")["policy"] = "other-policy"
        File.write(path, JSON.pretty_generate(record))

        _stdout, stderr, status = command("run", id, run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /policy/i])
      end
    end

    it "rejects an unsupported representation manifest version" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)
        path, record = observation_record(root, run_id, id: id)
        record.fetch("observation").fetch("representations").
          fetch("gp-runes-v1")["schema_version"] = 2
        File.write(path, JSON.pretty_generate(record))

        _stdout, stderr, status = command("run", id, run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /version|schema/i])
      end
    end

    it "rejects duplicate keys in a saved run record" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)
        path, _record = observation_record(root, run_id, id: id)
        bytes = File.binread(path)
        File.binwrite(path, bytes.sub('"status": "completed",',
                                      '"status": "completed", "status": "running",'))

        _stdout, stderr, status = command("run", id, run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /duplicate.*status/i])
      end
    end

    it "rejects a saved artifact symlink escaping its run directory" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)
        _path, record = observation_record(root, run_id, id: id)
        output = record.fetch("artifacts").fetch("output.txt").fetch("path")
        outside = File.join(directory, "outside.txt")
        File.binwrite(outside, File.binread(output))
        File.delete(output)
        File.symlink(outside, output)

        _stdout, stderr, status = command("run", id, run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /symlink|escap|path/i])
      end
    end
  end

  describe "analyses review" do
    it "shows a retained running attempt as incomplete" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)
        command("run", id, run_id, "--definition", definition,
                "--output-path", root)
        record_path = Dir.glob(File.join(root, id, run_id, "analyses", "*",
                                         "record.json")).fetch(0)
        record = JSON.parse(File.binread(record_path))
        record.merge!("status" => "running", "completed_at" => nil,
                      "results" => [], "errors" => [])
        File.binwrite(record_path, JSON.pretty_generate(record))

        stdout, _stderr, _status = command("review", id, run_id,
                                            "--output-path", root)

        expect(stdout.lines.map(&:strip)).to include("status: running")
      end
    end

    it "shows a retained execution error separately from a measurement" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)
        command("run", id, run_id, "--definition", definition,
                "--output-path", root)
        record_path = Dir.glob(File.join(root, id, run_id, "analyses", "*",
                                         "record.json")).fetch(0)
        record = JSON.parse(File.binread(record_path))
        record.merge!("status" => "error", "results" => [],
                      "errors" => [{ "type" => "RuntimeError",
                                     "message" => "analysis interrupted" }])
        File.binwrite(record_path, JSON.pretty_generate(record))

        stdout, _stderr, _status = command("review", id, run_id,
                                            "--output-path", root)

        expect(stdout.lines.map(&:strip)).to include("status: error")
      end
    end

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

    it "reviews retained measurements after the source artifacts disappear" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        run_id = completed_observation(root)
        definition = analysis_definition(directory)
        command("run", "page-57-latin", run_id,
                "--definition", definition, "--output-path", root)
        _path, record = observation_record(root, run_id)
        artifacts = record.fetch("artifacts")
        File.delete(artifacts.fetch("output.txt").fetch("path"))
        File.delete(artifacts.fetch("provenance.json").fetch("path"))

        stdout, _stderr, status = command("review", "page-57-latin", run_id,
                                          "--output-path", root)

        expect([status.success?, stdout]).to match([true, a_string_including(
          "gp-runes-v1", "gp-expanded-latin-v1", "raw IC",
        )])
      end
    end

    it "reports a corrupt retained analysis record explicitly" do
      Dir.mktmpdir do |directory|
        root = File.join(directory, "runs")
        id, run_id = independent_three_rune_observation(root)
        definition = analysis_definition(directory)
        command("run", id, run_id, "--definition", definition,
                "--output-path", root)
        record_path = Dir.glob(File.join(root, id, run_id, "analyses", "*",
                                         "record.json")).fetch(0)
        File.write(record_path, "{broken")

        _stdout, stderr, status = command("review", id, run_id,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /record|json|parse/i])
      end
    end
  end
end
