require "tmpdir"

RSpec.describe Primus::Analysis::Definition do
  def write_definition(root, stages)
    analyses = stages.each_with_index.map do |stage, index|
      { "id" => "count-#{index}", "analyzer" => "symbol-statistics", "version" => 1,
        "target" => { "stage" => stage,
                      "representation" => %w[gp-runes-v1 gp-expanded-latin-v1].fetch(index) } }
    end
    path = File.join(root, "analysis.yml")
    File.write(path, Psych.dump("schema_version" => 1, "id" => "checkpoint-count",
                                "analyses" => analyses))
    path
  end

  describe "#stage" do
    it "exposes an original selection shared by both declarations" do
      Dir.mktmpdir do |root|
        path = write_definition(root, %w[original original])

        definition = described_class.new(path: path)

        expect(definition.stage).to eq("original")
      end
    end

    it "exposes a declared step selection" do
      Dir.mktmpdir do |root|
        path = write_definition(root, %w[first])

        definition = described_class.new(path: path)

        expect(definition.stage).to eq("first")
      end
    end

    it "accepts a safe selector for later membership resolution" do
      Dir.mktmpdir do |root|
        path = write_definition(root, %w[unknown])

        definition = described_class.new(path: path)

        expect(definition.stage).to eq("unknown")
      end
    end
  end

  describe "#initialize" do
    it "rejects two declarations aimed at different checkpoints" do
      Dir.mktmpdir do |root|
        path = write_definition(root, %w[final letters])

        action = -> { described_class.new(path: path) }

        expect(action).to raise_error(described_class::Error)
      end
    end

    it "rejects an unsafe traversal selector" do
      Dir.mktmpdir do |root|
        path = write_definition(root, ["../first"])

        action = -> { described_class.new(path: path) }

        expect(action).to raise_error(described_class::Error)
      end
    end

    it "rejects a numeric checkpoint ordinal" do
      Dir.mktmpdir do |root|
        path = write_definition(root, ["1"])

        action = -> { described_class.new(path: path) }

        expect(action).to raise_error(described_class::Error)
      end
    end
  end
end
