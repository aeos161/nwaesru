class Primus::Commands::RepeatedNgramPresenter
  def initialize(result:, stage:)
    @result, @stage = result, stage
  end

  def lines
    [heading, policy] + group_lines + source_lines
  end

  private

  def units
    @result.representation == "gp-runes-v1" ? "GP runes" : "expanded Latin letters"
  end

  def heading
    "#{@result.declaration_id} #{@stage} #{units}: sequence repetition, sample size #{@result.sample_size}"
  end

  def policy
    "boundary policy: #{@result.boundary_policy}; overlapping starts use current zero-based, end-exclusive #{units} indices"
  end

  def group_lines
    @result.length_groups.flat_map { |group| [group_heading(group)] + pattern_lines(group) }
  end

  def group_heading(group)
    "length #{group.fetch('length')}: #{group.fetch('status')}; candidate count #{group.fetch('candidate_count')}; distinct patterns #{group.fetch('distinct_pattern_count')}; repeated patterns #{group.fetch('repeated_pattern_count')}; repeated occurrences #{group.fetch('repeated_occurrence_count')}"
  end

  def pattern_lines(group)
    group.fetch("patterns").map do |pattern|
      starts = pattern.fetch("occurrences").map { |item| item.fetch("start_index") }
      "pattern #{pattern.fetch('symbols').join} count #{pattern.fetch('count')} starts #{starts.inspect} consecutive gaps #{pattern.fetch('gaps').inspect}"
    end
  end

  def source_lines
    @result.position_map.each_with_index.map do |position, index|
      "source map #{index}: #{position.inspect}"
    end
  end
end
