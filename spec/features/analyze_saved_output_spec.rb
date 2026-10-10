require "json"
require "digest"
require "fileutils"
require "open3"
require "tmpdir"

RSpec.describe "saved output analysis lifecycle" do
  GP_ALPHABET = %w[ᚠ ᚢ ᚦ ᚩ ᚱ ᚳ ᚷ ᚹ ᚻ ᚾ ᛁ ᛄ ᛇ ᛈ ᛉ ᛋ ᛏ ᛒ ᛖ ᛗ ᛚ ᛝ ᛟ ᛞ ᚪ ᚫ ᚣ ᛡ ᛠ].freeze
  GP_EXPANSIONS = %w[f u th o r c g w h n i j eo p x s t b e m l ng oe d a ae y io ea].freeze

  def independent_three_rune_observation(root)
    id = "tiny-final"
    run_id = "20261009T000000-000000000001"
    directory = File.join(root, id, run_id)
    FileUtils.mkdir_p(directory)
    output = "thath"
    runes = %w[ᚦ ᚪ ᚦ]
    letters = %w[th a th]
    rows = runes.each_with_index.map do |rune, index|
      { "ordinal" => index, "rune" => rune, "decoded_rune" => rune,
        "latin" => letters.fetch(index), "page_number" => 57,
        "occurrence" => 0, "byte_start" => index * 3,
        "byte_end" => (index + 1) * 3, "character_start" => index,
        "character_end" => index + 1, "line" => 0,
        "column" => index, "rune_index" => index }
    end
    provenance = JSON.pretty_generate(rows)
    output_digest = Digest::SHA256.hexdigest(output)
    provenance_digest = Digest::SHA256.hexdigest(provenance)
    File.binwrite(File.join(directory, "output.txt"), output)
    File.binwrite(File.join(directory, "provenance.json"), provenance)
    common = { "schema_version" => 1, "stage" => "final",
               "artifact" => "provenance.json", "symbol_field" => "decoded_rune",
               "output_sha256" => output_digest,
               "provenance_sha256" => provenance_digest }
    profiles = {
      "gp-runes-v1" => common.merge("alphabet" => GP_ALPHABET, "sample_size" => 3),
      "gp-expanded-latin-v1" => common.merge(
        "alphabet" => ("a".."z").to_a, "sample_size" => 5,
        "expansion_map" => GP_ALPHABET.zip(GP_EXPANSIONS).to_h,
      ),
    }
    record = {
      "schema_version" => 2, "experiment_id" => id, "run_id" => run_id,
      "status" => "completed", "completed_at" => "2026-10-09T00:00:00Z",
      "configuration" => { "output" => { "policy" => "gp-latin-compatibility-v1" } },
      "observation" => { "output_bytes" => 5, "representations" => profiles },
      "artifacts" => {
        "output.txt" => { "path" => File.join(directory, "output.txt"),
                          "bytes" => 5, "sha256" => output_digest },
        "provenance.json" => { "path" => File.join(directory, "provenance.json"),
                               "bytes" => provenance.bytesize,
                               "sha256" => provenance_digest },
      },
    }
    File.write(File.join(directory, "record.json"), JSON.pretty_generate(record))
    [id, run_id]
  end

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

        _stdout, stderr, status = command("run", "page-57-latin", run_id,
                                           "--definition", definition,
                                           "--output-path", root)

        expect([status.success?, stderr]).to match([false, /output.*(bytes|digest|sha|size)/i])
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
  end
end
