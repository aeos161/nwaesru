RSpec.describe "Primus::Experiment" do
  def fixture(name)
    "spec/fixtures/experiments/#{name}"
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

    it "rejects an unsupported page number" do
      experiment = Primus::Experiment.load(
        path: fixture("page_57_wrong_page.yml"),
      )

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
