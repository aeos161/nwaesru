require "tmpdir"

RSpec.describe Primus::Experiment do
  def load_definition(check)
    Dir.mktmpdir do |directory|
      path = File.join(directory, "composition.yml")
      File.write(path, <<~YAML)
        schema_version: 2
        id: page-57-composed
        title: Page 57 Latin check
        purpose: Compare the whole-page Latin result.
        input:
          id: page-57
          sha256: c7055db0173e43eb231608812f5d52569e4c0817934b1a65427cebf332759fff
        recipe:
          id: latin
        output:
          policy: gp-latin-compatibility-v1
        checks:
          - id: check-1
      YAML
      File.open(path, "a") { |file| file.write(check) }
      yield Primus::Experiment.load(path: path)
    end
  end

  describe "#valid?" do
    it "rejects a 32-byte target for a 64-byte SHA-512 check" do
      check = <<~YAML
            strategy: hash
            algorithm: sha512
            expectation:
              digest: #{'a' * 64}
              provenance: Independent known answer.
      YAML
      load_definition(check) do |experiment|
        experiment.valid?

        expect(experiment.errors.attribute_names).to include(:checks)
      end
    end

    it "rejects an unsupported hash algorithm" do
      check = <<~YAML
            strategy: hash
            algorithm: sha256
            expectation:
              digest: #{'a' * 64}
              provenance: Independent known answer.
      YAML
      load_definition(check) do |experiment|
        experiment.valid?

        expect(experiment.errors.attribute_names).to include(:checks)
      end
    end

    it "requires expectation provenance in YAML" do
      check = <<~YAML
            strategy: hash
            algorithm: sha512
            expectation:
              digest: f3fac0115ab06d1a4075731e77fe157ad52b837b9068bf942c95784160578f43a1a72e770f2e2c1b00a1bc2fad39dc66fa78efd28c5cd976ed3a35f3e400bcab
      YAML
      load_definition(check) do |experiment|
        experiment.valid?

        expect(experiment.errors.attribute_names).to include(:checks)
      end
    end
  end
end
