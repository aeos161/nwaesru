RSpec.describe "Primus::Analysis::ICInterpretation" do
  def reference_packet
    {
      "id" => "synthetic-controls-v1",
      "representation" => "gp-runes-v1",
      "uniform" => { "numerator" => 1, "denominator" => 29 },
      "controls" => [
        { "id" => "low", "sample_size" => 29,
          "numerator" => 84, "denominator" => 812 },
        { "id" => "high", "sample_size" => 29,
          "numerator" => 140, "denominator" => 812 },
      ],
      "provenance_digest" => "a" * 64,
      "source_description" => "independent synthetic comparator",
    }
  end

  def measured_ic(numerator:, denominator:, sample_size: 29,
                  representation: "gp-runes-v1", status: "computed")
    { "representation" => representation, "sample_size" => sample_size,
      "ic" => { "status" => status, "normalization" => "none",
                "numerator" => numerator, "denominator" => denominator,
                "value" => denominator.zero? ? nil : numerator.to_f / denominator } }
  end

  def interpretation(measurement, references = reference_packet)
    Primus::Analysis::ICInterpretation.new(
      measurement: measurement, references: references,
    ).to_h
  end

  describe "#to_h" do
    context "with fewer than two symbols" do
      it "marks N=0 insufficient with its retained sample size" do
        measurement = measured_ic(numerator: 0, denominator: 0,
                                  sample_size: 0, status: "insufficient_sample")

        snapshot = interpretation(measurement)

        expect(snapshot).to include("judgment_code" => "insufficient_sample",
                                    "sample_size" => 0)
      end

      it "marks N=1 as insufficient rather than reporting zero collisions" do
        measurement = measured_ic(numerator: 0, denominator: 0,
                                  sample_size: 1, status: "insufficient_sample")

        snapshot = interpretation(measurement)

        expect(snapshot.fetch("text")).to eq(
          "English comparison: insufficient evidence — fewer than two symbols; IC is undefined."
        )
      end
    end

    context "with a computed IC" do
      it "places N=2 with no collision closer to the uniform benchmark" do
        measurement = measured_ic(numerator: 0, denominator: 2, sample_size: 2)

        snapshot = interpretation(measurement)

        expect(snapshot.fetch("judgment_code")).to eq("closer_to_uniform")
      end

      it "places balanced finite counts with IC inside the control range" do
        measurement = measured_ic(numerator: 112, denominator: 812)

        snapshot = interpretation(measurement)

        expect(snapshot.fetch("judgment_code")).to eq("within_controls")
      end

      it "includes the lower control endpoint in the observed range" do
        measurement = measured_ic(numerator: 84, denominator: 812)

        snapshot = interpretation(measurement)

        expect(snapshot.fetch("judgment_code")).to eq("within_controls")
      end

      it "includes the upper control endpoint in the observed range" do
        measurement = measured_ic(numerator: 140, denominator: 812)

        snapshot = interpretation(measurement)

        expect(snapshot.fetch("judgment_code")).to eq("within_controls")
      end

      it "places a below-range IC near the lower control closer to a control" do
        measurement = measured_ic(numerator: 70, denominator: 812)

        snapshot = interpretation(measurement)

        expect(snapshot.fetch("judgment_code")).to eq("closer_to_control")
      end

      it "places a near-uniform below-range IC closer to uniform" do
        measurement = measured_ic(numerator: 42, denominator: 812)

        snapshot = interpretation(measurement)

        expect(snapshot.fetch("judgment_code")).to eq("closer_to_uniform")
      end

      it "recognizes an exact distance tie before display rounding" do
        measurement = measured_ic(numerator: 56, denominator: 812)

        snapshot = interpretation(measurement)

        expect(snapshot.fetch("judgment_code")).to eq("equal_distance")
      end

      it "labels IC=1 as above both controls without stronger English support" do
        measurement = measured_ic(numerator: 812, denominator: 812)

        snapshot = interpretation(measurement)

        expect(snapshot.fetch("text")).to include(
          "More concentrated than both solved English controls; " \
          "higher IC does not mean closer to English."
        )
      end

      it "retains exact signed differences rather than rounded decimals" do
        measurement = measured_ic(numerator: 56, denominator: 812)

        snapshot = interpretation(measurement)

        expect(snapshot.fetch("differences")).to include(
          "low" => { "numerator" => -1, "denominator" => 29 },
          "high" => { "numerator" => -3, "denominator" => 29 },
        )
      end

      it "retains the GP-29 theoretical benchmark separately from controls" do
        measurement = measured_ic(numerator: 56, denominator: 812)

        snapshot = interpretation(measurement)

        expect(snapshot.fetch("theoretical_uniform")).to eq(
          "numerator" => 1, "denominator" => 29,
        )
      end

      it "does not freeze caller-owned reference data while retaining its own snapshot" do
        measurement = measured_ic(numerator: 56, denominator: 812)
        references = reference_packet
        snapshot = interpretation(measurement, references)

        references.fetch("controls").first["numerator"] = 0

        expect(snapshot.fetch("references").first.fetch("numerator")).to eq(84)
      end

      it "freezes nested reference details in its owned snapshot" do
        measurement = measured_ic(numerator: 56, denominator: 812)

        snapshot = interpretation(measurement)

        expect(snapshot.fetch("references").first).to be_frozen
      end

      it "gives permuted samples with the same histogram the same judgment" do
        alphabet = Primus::Analysis::RUNES
        original = Primus::Analysis::SymbolStatistics.new(
          symbols: %w[ᚦ ᚪ ᚦ], alphabet: alphabet,
          declaration_id: "sample", representation: "gp-runes-v1",
        ).to_result.to_h
        permuted = Primus::Analysis::SymbolStatistics.new(
          symbols: %w[ᚪ ᚦ ᚦ], alphabet: alphabet,
          declaration_id: "sample", representation: "gp-runes-v1",
        ).to_result.to_h

        original_code = interpretation(original).fetch("judgment_code")
        permuted_code = interpretation(permuted).fetch("judgment_code")

        expect(permuted_code).to eq(original_code)
      end
    end

    context "with a representation-matched Latin reference" do
      it "uses the Latin-26 theoretical benchmark" do
        measurement = measured_ic(numerator: 0, denominator: 2,
                                  sample_size: 2, representation: "gp-expanded-latin-v1")
        references = reference_packet.merge(
          "representation" => "gp-expanded-latin-v1",
          "uniform" => { "numerator" => 1, "denominator" => 26 },
        )

        snapshot = interpretation(measurement, references)

        expect(snapshot.fetch("theoretical_uniform")).to eq(
          "numerator" => 1, "denominator" => 26,
        )
      end
    end

    context "without a compatible English reference" do
      it "marks a known GP alphabet insufficient for English comparison" do
        measurement = measured_ic(numerator: 2, denominator: 2, sample_size: 2)

        snapshot = interpretation(measurement, nil)

        expect(snapshot.fetch("text")).to eq(
          "English comparison: insufficient evidence — no compatible English reference is available."
        )
      end

      it "does not infer a GP or Latin alphabet for an unknown representation" do
        measurement = measured_ic(numerator: 2, denominator: 2,
                                  sample_size: 2, representation: "unknown-v1")

        snapshot = interpretation(measurement, nil)

        expect(snapshot.fetch("theoretical_uniform")).to be_nil
      end
    end
  end
end
