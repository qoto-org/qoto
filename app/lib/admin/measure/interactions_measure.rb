# frozen_string_literal: true

class Admin::Measure::InteractionsMeasure < Admin::Measure::BaseMeasure
  def key
    'interactions'
  end

  def total
    Redis.current.pfcount(*time_period.map { |cweek| "activity:interactions:#{cweek}" })
  end

  def previous_total
    Redis.current.pfcount(*previous_time_period.map { |cweek| "activity:interactions:#{cweek}" })
  end

  def data
    time_period.map { |cweek| { date: Date.commercial(@start_at.cwyear, cweek).to_time.iso8601, value: Redis.current.pfcount("activity:interactions:#{cweek}") } }
  end

  private

  def time_period
    (@start_at.cweek...@end_at.cweek)
  end

  def previous_time_period
    ((@start_at.cweek - time_period.size)...(@end_at.cweek - time_period.size))
  end
end
