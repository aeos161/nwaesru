class Primus::Analysis::ICJudgment
  def initialize(measured:, controls:, uniform:)
    @measured, @controls, @uniform = measured, controls, uniform
  end

  def code
    return "above_controls" if @measured > @controls.max
    return "within_controls" if @measured >= @controls.min

    nearest = @controls.map { |control| (@measured - control).abs }.min
    uniform_distance = (@measured - @uniform).abs
    return "closer_to_control" if nearest < uniform_distance
    return "closer_to_uniform" if nearest > uniform_distance

    "equal_distance"
  end
end
