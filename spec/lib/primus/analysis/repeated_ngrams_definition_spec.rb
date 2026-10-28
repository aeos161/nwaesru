require "tmpdir"

RSpec.describe Primus::Analysis::Definition do
  def write_repeated_definition(root, entries)
    path = File.join(root, "repeated.yml")
    File.write(path, Psych.dump("schema_version" => 1, "id" => "repeated-check",
                                "analyses" => entries))
    path
  end

  def repeated_entry(parameters, representation: "gp-runes-v1", stage: "original")
    { "id" => "rune-repeats", "analyzer" => "repeated-ngrams", "version" => 1,
      "parameters" => parameters,
      "target" => { "stage" => stage, "representation" => representation } }
  end

  def parse_valid_repeated_definition(root)
    parameters = { "lengths" => [2], "boundary_policy" => "continuous-gp-v1" }
    path = write_repeated_definition(root, [repeated_entry(parameters)])
    described_class.new(path: path)
  end

  describe "#declarations" do
    it "accepts a bounded pair and triple declaration" do
      Dir.mktmpdir do |root|
        parameters = { "lengths" => [2, 3], "boundary_policy" => "continuous-gp-v1" }
        path = write_repeated_definition(root, [repeated_entry(parameters)])

        declaration = described_class.new(path: path).declarations.first

        expect(declaration.fetch("parameters")).to eq(parameters)
      end
    end

    it "accepts two representations of the same analyzer and stage" do
      Dir.mktmpdir do |root|
        parameters = { "lengths" => [2], "boundary_policy" => "continuous-gp-v1" }
        rune = repeated_entry(parameters)
        latin_parameters = { "lengths" => [2], "boundary_policy" => "continuous-gp-v1" }
        latin = repeated_entry(latin_parameters, representation: "gp-expanded-latin-v1")
        latin["id"] = "latin-repeats"
        path = write_repeated_definition(root, [rune, latin])

        declarations = described_class.new(path: path).declarations

        expect(declarations.map { |entry| entry.fetch("target").fetch("representation") }).
          to eq(%w[gp-runes-v1 gp-expanded-latin-v1])
      end
    end
  end

  describe "#initialize" do
    { "empty" => [], "duplicate" => [2, 2], "descending" => [3, 2],
      "too short" => [1], "too long" => [4], "boolean" => [true],
      "string" => ["2"], "float" => [2.0] }.each do |name, lengths|
      it "rejects #{name} lengths" do
        Dir.mktmpdir do |root|
          parse_valid_repeated_definition(root)
          parameters = { "lengths" => lengths, "boundary_policy" => "continuous-gp-v1" }
          path = write_repeated_definition(root, [repeated_entry(parameters)])

          action = -> { described_class.new(path: path) }

          expect(action).to raise_error(described_class::Error)
        end
      end
    end

    it "rejects an unknown boundary policy" do
      Dir.mktmpdir do |root|
        parse_valid_repeated_definition(root)
        parameters = { "lengths" => [2], "boundary_policy" => "line-separated" }
        path = write_repeated_definition(root, [repeated_entry(parameters)])

        action = -> { described_class.new(path: path) }

        expect(action).to raise_error(described_class::Error)
      end
    end

    it "rejects an unknown parameter" do
      Dir.mktmpdir do |root|
        parse_valid_repeated_definition(root)
        parameters = { "lengths" => [2], "boundary_policy" => "continuous-gp-v1",
                       "window" => 20 }
        path = write_repeated_definition(root, [repeated_entry(parameters)])

        action = -> { described_class.new(path: path) }

        expect(action).to raise_error(described_class::Error)
      end
    end

    it "rejects an unsupported repeated analyzer version" do
      Dir.mktmpdir do |root|
        parse_valid_repeated_definition(root)
        parameters = { "lengths" => [2], "boundary_policy" => "continuous-gp-v1" }
        entry = repeated_entry(parameters)
        entry["version"] = 2
        path = write_repeated_definition(root, [entry])

        action = -> { described_class.new(path: path) }

        expect(action).to raise_error(described_class::Error)
      end
    end

    it "rejects mixed analyzer families" do
      Dir.mktmpdir do |root|
        parse_valid_repeated_definition(root)
        parameters = { "lengths" => [2], "boundary_policy" => "continuous-gp-v1" }
        statistics = { "id" => "latin-counts", "analyzer" => "symbol-statistics",
                       "version" => 1,
                       "target" => { "stage" => "original",
                                     "representation" => "gp-expanded-latin-v1" } }
        path = write_repeated_definition(root, [repeated_entry(parameters), statistics])

        action = -> { described_class.new(path: path) }

        expect(action).to raise_error(described_class::Error, /mixed analyzer/i)
      end
    end
  end
end
