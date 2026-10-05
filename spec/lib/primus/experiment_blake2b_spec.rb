require "openssl"
require "tempfile"

RSpec.describe Primus::Experiment do
  def blake_definition
    Psych.safe_load(File.read(
                      "spec/fixtures/experiments/page_57_blake2b_valid.yml",
                    ))
  end

  def load_blake_variant
    definition = blake_definition
    yield definition
    load_definition(definition)
  end

  def load_definition(definition)
    Tempfile.create(["page-57-blake2b", ".yml"]) do |file|
      file.write(Psych.dump(definition))
      file.flush
      Primus::Experiment.load(path: file.path)
    end
  end

  describe "#valid?" do
    it "accepts the declared BLAKE2b-512 recipe without an oracle file" do
      experiment = Primus::Experiment.load(
        path: "spec/fixtures/experiments/page_57_blake2b_valid.yml",
      )

      expect(experiment).to be_valid
    end

    it "keeps SHA-512 bound to its own recipe ID" do
      experiment = load_blake_variant { |definition|
        definition["id"] = "page-57-latin-sha512"
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects SHA-512 under the BLAKE2b-512 recipe ID" do
      experiment = load_blake_variant { |definition|
        definition.fetch("expectation")["algorithm"] = "sha512"
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects an unsupported BLAKE2b alias" do
      experiment = load_blake_variant { |definition|
        definition.fetch("expectation")["algorithm"] = "blake2b"
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects a shortened digest" do
      experiment = load_blake_variant { |definition|
        definition.fetch("expectation")["digest"] = "0" * 127
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects keyed BLAKE2b parameters" do
      experiment = load_blake_variant { |definition|
        definition["parameters"] = { "key" => "secret" }
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:parameters])
    end

    it "rejects a different page under the BLAKE2b ID" do
      experiment = load_blake_variant { |definition|
        definition.fetch("input")["page_number"] = 56
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:base])
    end

    it "validates a well-formed digest without probing OpenSSL" do
      experiment = Primus::Experiment.load(
        path: "spec/fixtures/experiments/page_57_blake2b_valid.yml",
      )
      allow(OpenSSL::Digest).to receive(:new).and_raise("backend unavailable")

      valid = experiment.valid?

      expect(valid).to be_truthy
    end
  end
end
