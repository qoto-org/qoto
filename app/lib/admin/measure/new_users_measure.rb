# frozen_string_literal: true

class Admin::Measure::NewUsersMeasure < Admin::Measure::BaseMeasure
  def key
    'new_users'
  end

  def total
    Redis.current.mget(*time_period.map { |cweek| "activity:accounts:local:#{cweek}" }).map(&:to_i).sum
  end

  def previous_total
    Redis.current.mget(*previous_time_period.map { |cweek| "activity:accounts:local:#{cweek}" }).map(&:to_i).sum
  end

  def data
    time_period.map { |cweek| { date: Date.commercial(@start_at.cwyear, cweek).to_time.iso8601, value: Redis.current.get("activity:accounts:local:#{cweek}").to_i } }
  end

  private

  def time_period
    (@start_at.cweek...@end_at.cweek)
  end

  def previous_time_period
    ((@start_at.cweek - time_period.size)...(@end_at.cweek - time_period.size))
  end
end
