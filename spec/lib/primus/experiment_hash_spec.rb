require "tempfile"

RSpec.describe Primus::Experiment do
  def hash_definition
    Psych.safe_load(File.read(
                      "spec/fixtures/experiments/page_57_hash_valid.yml",
                    ))
  end

  def load_variant
    definition = hash_definition
    yield definition
    load_definition(definition)
  end

  def load_definition(definition)
    Tempfile.create(["page-57-hash", ".yml"]) do |file|
      file.write(Psych.dump(definition))
      file.flush
      Primus::Experiment.load(path: file.path)
    end
  end

  describe "#valid?" do
    it "accepts the declared page 57 SHA-512 recipe without an oracle file" do
      experiment = Primus::Experiment.load(
        path: "spec/fixtures/experiments/page_57_hash_valid.yml",
      )

      expect(experiment).to be_valid
    end

    it "rejects the hash expectation under the plaintext page 57 ID" do
      experiment = load_variant { |definition|
        definition["id"] = "page-57-latin"
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects a plaintext expectation under the hash ID" do
      path = "spec/fixtures/experiments/page_57_valid.yml"
      experiment = load_variant { |definition|
        plaintext = Psych.safe_load(File.read(path))
        definition["expectation"] = plaintext.fetch("expectation")
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects the hash ID paired with page 56" do
      experiment = load_variant { |definition|
        definition.fetch("input")["page_number"] = 56
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:base])
    end

    it "rejects the hash ID paired with a different operation" do
      experiment = load_variant { |definition|
        definition["operation"] = "totient_shift_to_latin"
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:base])
    end

    it "rejects unsupported hash algorithms" do
      experiment = load_variant { |definition|
        definition.fetch("expectation")["algorithm"] = "sha256"
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects a missing hash algorithm" do
      experiment = load_variant { |definition|
        definition.fetch("expectation").delete("algorithm")
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects a null hash digest" do
      experiment = load_variant { |definition|
        definition.fetch("expectation")["digest"] = nil
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects a missing hash digest" do
      experiment = load_variant { |definition|
        definition.fetch("expectation").delete("digest")
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects a nonstring hash digest" do
      experiment = load_variant { |definition|
        definition.fetch("expectation")["digest"] = 123
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects a short hash digest" do
      experiment = load_variant { |definition|
        definition.fetch("expectation")["digest"] = "a" * 127
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects an uppercase hash digest" do
      experiment = load_variant { |definition|
        definition.fetch("expectation")["digest"] = "A" * 128
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects a whitespace-padded hash digest" do
      experiment = load_variant { |definition|
        definition.fetch("expectation")["digest"] = " #{"a" * 128} "
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects hash expectations with plaintext-only keys" do
      experiment = load_variant { |definition|
        definition.fetch("expectation")["path"] = "unused.txt"
      }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "rejects plaintext expectations with hash-only keys" do
      path = "spec/fixtures/experiments/page_57_valid.yml"
      definition = Psych.safe_load(File.read(path))
      definition.fetch("expectation")["algorithm"] = "sha512"
      experiment = load_variant { |variant| variant.replace(definition) }

      experiment.valid?

      expect(experiment.errors.attribute_names.uniq).to eq([:expectation])
    end

    it "accepts a well-formed but scientifically wrong digest" do
      experiment = load_variant { |definition|
        definition.fetch("expectation")["digest"] = "0" * 128
      }

      expect(experiment).to be_valid
    end
  end

  describe "#expected_bytes" do
    it "uses nil for a hash expectation without a plaintext oracle" do
      experiment = Primus::Experiment.load(
        path: "spec/fixtures/experiments/page_57_hash_valid.yml",
      )

      experiment.valid?

      expect(experiment.expected_bytes).to be_nil
    end
  end

  describe "#expectation_digest" do
    it "keeps the oracle SHA-256 identity nil for a hash expectation" do
      experiment = Primus::Experiment.load(
        path: "spec/fixtures/experiments/page_57_hash_valid.yml",
      )

      experiment.valid?

      expect(experiment.expectation_digest).to be_nil
    end
  end
end
