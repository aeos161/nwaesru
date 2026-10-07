RSpec.describe "Primus::Experiment::Blake512" do
  describe "#hexdigest" do
    it "hashes the original BLAKE-512 abc vector" do
      digest = "14266c7c704a3b58fb421ee69fd005fc" \
               "c6eeff742136be67435df995b7c986e7" \
               "cbde4dbde135e7689c354d2bc5b8d260" \
               "536c554b4f84c118e61efc576fed7cd3"

      observed = Primus::Experiment::Blake512.new.hexdigest("abc")

      expect(observed).to eq(digest)
    end

    it "hashes binary bytes without character conversion" do
      bytes = "\x00\xff\x80\x7f\x00\xfe\x81\x82".b
      digest = "ff189da5eb30bbd216163b29d8cbebb3" \
               "f428a60a14c6e18e22a0a2180476c795" \
               "c516f3af0adcbc6184c7abd027637009" \
               "0ee1244494a3de88b745acc81ec6d1b0"

      observed = Primus::Experiment::Blake512.new.hexdigest(bytes)

      expect(observed).to eq(digest)
    end

    it "translates a native load failure to typed unavailability" do
      backend = Primus::Experiment::Blake512.new
      allow(backend).to receive(:require).with("aeos/blake512").
        and_raise(LoadError, "native load failed")

      action = -> { backend.hexdigest("abc") }

      expect(action).to raise_error(Primus::Experiment::Blake512::Unavailable)
    end

    it "translates BuildMismatch from the gem to typed unavailability" do
      require "aeos/blake512"
      backend = Primus::Experiment::Blake512.new
      allow(backend).to receive(:require).with("aeos/blake512").
        and_raise(Aeos::Blake512::BuildMismatch, "stale native build")

      action = -> { backend.hexdigest("abc") }

      expect(action).to raise_error(Primus::Experiment::Blake512::Unavailable)
    end
  end

  describe "#runtime" do
    it "reports an available schema-1 original BLAKE-512 descriptor" do
      runtime = Primus::Experiment::Blake512.new.runtime

      expect(runtime).to include("backend" => "blake512-ruby",
                                 "available" => true,
                                 "schema_version" => 1,
                                 "algorithm" => "blake512")
    end

    it "reports an unavailable descriptor after a native load failure" do
      backend = Primus::Experiment::Blake512.new
      allow(backend).to receive(:require).with("aeos/blake512").
        and_raise(LoadError, "native load failed")

      runtime = backend.runtime

      expect(runtime).to include("backend" => "blake512-ruby",
                                 "available" => false)
    end

    it "treats an unsupported build descriptor schema as unavailable" do
      require "aeos/blake512"
      backend = Primus::Experiment::Blake512.new
      allow(Aeos::Blake512).to receive(:build_info).
        and_return("schema_version" => 2)

      runtime = backend.runtime

      expect(runtime).to include("backend" => "blake512-ruby",
                                 "available" => false)
    end
  end
end
