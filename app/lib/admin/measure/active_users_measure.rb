# frozen_string_literal: true

class Admin::Measure::ActiveUsersMeasure < Admin::Measure::BaseMeasure
  def key
    'active_users'
  end

  def total
    Redis.current.pfcount(*time_period.map { |cweek| "activity:logins:#{cweek}" })
  end

  def previous_total
    Redis.current.pfcount(*previous_time_period.map { |cweek| "activity:logins:#{cweek}" })
  end

  def data
    time_period.map { |cweek| { date: Date.commercial(@start_at.cwyear, cweek).to_time.iso8601, value: Redis.current.pfcount("activity:logins:#{cweek}") } }
  end

  private

  def time_period
    (@start_at.cweek...@end_at.cweek)
  end

  def previous_time_period
    ((@start_at.cweek - time_period.size)...(@end_at.cweek - time_period.size))
  end
end
