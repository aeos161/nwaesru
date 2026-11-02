class Primus::Commands::RepeatedNgramPresenter
  ROW_LIMIT = 10
  VALUE_LIMIT = 8

  def initialize(result:, stage:, details: false)
    @result, @stage, @details = result, stage, details
  end

  def lines
    [heading, policy, latin_note].compact + group_lines + source_lines
  end

  private

  def units
    @result.representation == "gp-runes-v1" ? "GP runes" : "expanded Latin letters"
  end

  def heading
    "#{@result.declaration_id} #{@stage} #{units}: sequence repetition, sample size #{@result.sample_size}"
  end

  def policy
    "boundary policy: #{@result.boundary_policy}; overlapping starts are zero-based current #{units} indices; each span ends at start + length (end-exclusive)"
  end

  def latin_note
    return unless @result.representation == "gp-expanded-latin-v1"
    "Canonical expansions can repeat within one source rune; this is not evidence of English or an improved decryption."
  end

  def group_lines
    @result.length_groups.flat_map { |group| [group_heading(group)] + pattern_lines(group) }
  end

  def group_heading(group)
    "length #{group.fetch('length')}: #{group.fetch('status')}; candidate count #{group.fetch('candidate_count')}; distinct patterns #{group.fetch('distinct_pattern_count')}; repeated patterns #{group.fetch('repeated_pattern_count')}; overlapping occurrences #{group.fetch('repeated_occurrence_count')}"
  end

  def pattern_lines(group)
    return ["insufficient sample: N < #{group.fetch('length')}"] if group.fetch("status") == "insufficient_sample"
    patterns = group.fetch("patterns")
    return ["No repeated patterns among computed candidates."] if patterns.empty?
    ranked = patterns.sort_by { |pattern| -pattern.fetch("count") }
    displayed = @details ? ranked : ranked.first(ROW_LIMIT)
    ["pattern | count | starts | consecutive start-to-start gaps"] +
      displayed.map { |pattern| pattern_line(pattern) } + omitted_rows(ranked, displayed)
  end

  def pattern_line(pattern)
    starts = pattern.fetch("occurrences").map { |item| item.fetch("start_index") }
    "#{pattern.fetch('symbols').join} | #{pattern.fetch('count')} | starts: #{values(starts)} | gaps: #{values(pattern.fetch('gaps'))}"
  end

  def values(items)
    shown = @details ? items : items.first(VALUE_LIMIT)
    text = shown.join(", ")
    omitted = items.length - shown.length
    omitted.positive? ? "#{text} … #{omitted} omitted" : text
  end

  def omitted_rows(ranked, displayed)
    omitted = ranked.length - displayed.length
    omitted.positive? ? ["#{omitted} pattern#{'s' unless omitted == 1} omitted"] : []
  end

  def source_lines
    return [] unless @details
    ["Source map (index in current #{units} sequence; occurrence spans [start, end)):"] +
      @result.position_map.each_with_index.map { |position, index| source_line(position, index) }
  end

  def source_line(position, index)
    fields = position.map { |key, value| "#{key} #{value}" }.join(", ")
    "source map #{index}: #{fields}"
  end
end
