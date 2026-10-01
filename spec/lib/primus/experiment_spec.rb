require "tempfile"

RSpec.describe "Primus::Experiment" do
  def fixture(name)
    "spec/fixtures/experiments/#{name}"
  end

  def page_56_variant
    definition = Psych.safe_load(File.read(fixture("page_56_valid.yml")))
    yield definition
    load_temp_definition(definition)
  end

  def load_temp_definition(definition)
    Tempfile.create(["experiment-variant", ".yml"]) do |file|
      file.write(Psych.dump(definition))
      file.flush
      Primus::Experiment.load(path: file.path)
    end
  end

  describe ".load" do
    it "hydrates the saved page 57 identity" do
      path = fixture("page_57_valid.yml")

      experiment = Primus::Experiment.load(path: path)

      expect(experiment).to have_attributes(id: "page-57-latin",
                                            operation: "runes_to_latin")
    end

    it "rejects a duplicate YAML key before hydration" do
      path = fixture("page_57_duplicate.yml")

      action = -> { Primus::Experiment.load(path: path) }

      expect(action).to raise_error(Primus::Experiment::LoadError)
    end

    it "rejects malformed YAML before hydration" do
      path = fixture("page_57_malformed.yml")

      action = -> { Primus::Experiment.load(path: path) }

      expect(action).to raise_error(Primus::Experiment::LoadError)
    end

    it "rejects aliases before hydration" do
      path = fixture("page_57_alias.yml")

      action = -> { Primus::Experiment.load(path: path) }

      expect(action).to raise_error(Primus::Experiment::LoadError)
    end

    it "rejects a nonmapping YAML root" do
      path = fixture("page_57_sequence.yml")

      action = -> { Primus::Experiment.load(path: path) }

      expect(action).to raise_error(Primus::Experiment::LoadError)
    end

    it "rejects invalid UTF-8 definition bytes" do
      path = fixture("page_57_invalid_utf8.yml")

      action = -> { Primus::Experiment.load(path: path) }

      expect(action).to raise_error(Primus::Experiment::LoadError)
    end

    it "identifies a missing definition file as a load failure" do
      path = fixture("absent-definition.yml")

      action = -> { Primus::Experiment.load(path: path) }

      expect(action).to raise_error(Primus::Experiment::LoadError)
    end
  end

  describe "#valid?" do
    it "accepts the valid page 57 definition" do
      experiment = Primus::Experiment.load(path: fixture("page_57_valid.yml"))

      expect(experiment).to be_valid
    end

    it "rejects an unsupported operation" do
      experiment = Primus::Experiment.load(
        path: fixture("page_57_unsupported.yml"),
      )

      expect(experiment).not_to be_valid
    end

    it "rejects an unknown definition field" do
      experiment = Primus::Experiment.load(
        path: fixture("page_57_unknown_field.yml"),
      )

      expect(experiment).not_to be_valid
    end

    it "rejects a path that escapes the repository" do
      experiment = Primus::Experiment.load(
        path: fixture("page_57_unsafe_path.yml"),
      )

      expect(experiment).not_to be_valid
    end

    it "rejects a page number cross-wired with the page 57 recipe" do
      experiment = Primus::Experiment.load(
        path: fixture("page_57_wrong_page.yml"),
      )

      expect(experiment).not_to be_valid
    end

    it "accepts the page 56 totient recipe" do
      experiment = Primus::Experiment.load(path: fixture("page_56_valid.yml"))

      expect(experiment).to be_valid
    end

    it "rejects a page 56 recipe with the page 57 identity" do
      experiment = Primus::Experiment.load(path: fixture("page_56_valid.yml"))
      experiment.id = "page-57-latin"

      expect(experiment).not_to be_valid
    end

    it "rejects a page 56 recipe with the page 57 operation" do
      experiment = Primus::Experiment.load(path: fixture("page_56_valid.yml"))
      experiment.operation = "runes_to_latin"

      expect(experiment).not_to be_valid
    end

    it "rejects a page 56 recipe with the page 57 input path" do
      experiment = Primus::Experiment.load(path: fixture("page_56_valid.yml"))
      experiment.input["path"] = "data/encoded/liber_primus/page_57.yml"

      expect(experiment).not_to be_valid
    end

    it "rejects page 56 without recipe parameters" do
      experiment = page_56_variant { |definition|
        definition.delete("parameters")
      }

      expect(experiment).not_to be_valid
    end

    it "rejects page 56 parameters that are not a mapping" do
      experiment = page_56_variant { |definition|
        definition["parameters"] = [29, 2, 56]
      }

      expect(experiment).not_to be_valid
    end

    it "rejects a missing prime start parameter" do
      experiment = page_56_variant { |definition|
        definition.fetch("parameters").delete("prime_start")
      }

      expect(experiment).not_to be_valid
    end

    it "rejects an unknown page 56 parameter" do
      experiment = page_56_variant { |definition|
        definition.fetch("parameters")["direction"] = "add"
      }

      expect(experiment).not_to be_valid
    end

    it "rejects a string modulus" do
      experiment = page_56_variant { |definition|
        definition.fetch("parameters")["modulus"] = "29"
      }

      expect(experiment).not_to be_valid
    end

    it "rejects a floating point prime start" do
      experiment = page_56_variant { |definition|
        definition.fetch("parameters")["prime_start"] = 2.0
      }

      expect(experiment).not_to be_valid
    end

    it "rejects a different skip sequence" do
      experiment = page_56_variant { |definition|
        definition.fetch("parameters")["skip_sequence"] = [55]
      }

      expect(experiment).not_to be_valid
    end

    it "rejects cipher parameters on the page 57 recipe" do
      definition = Psych.safe_load(File.read(fixture("page_57_valid.yml")))
      definition["parameters"] = {}
      experiment = load_temp_definition(definition)

      expect(experiment).not_to be_valid
    end

    it "rejects an oracle whose digest does not match" do
      experiment = Primus::Experiment.load(
        path: fixture("page_57_wrong_oracle_digest.yml"),
      )

      expect(experiment).not_to be_valid
    end

    it "rejects an input whose digest does not match" do
      experiment = Primus::Experiment.load(
        path: fixture("page_57_wrong_digest.yml"),
      )

      expect(experiment).not_to be_valid
    end

    it "rejects a missing expected text file" do
      experiment = Primus::Experiment.load(
        path: fixture("page_57_missing_oracle.yml"),
      )

      expect(experiment).not_to be_valid
    end

    it "rejects invalid UTF-8 expected text before comparison" do
      experiment = Primus::Experiment.load(
        path: fixture("page_57_bad_oracle_encoding.yml"),
      )

      expect(experiment).not_to be_valid
    end
  end
end
