# frozen_string_literal: true

class Admin::Measure
  MEASURES = {
    active_users: Admin::Measure::ActiveUsersMeasure,
    new_users: Admin::Measure::NewUsersMeasure,
    interactions: Admin::Measure::InteractionsMeasure,
  }.freeze

  def self.retrieve(measure_keys, start_at, end_at)
    Array(measure_keys).map { |key| MEASURES[key.to_sym]&.new(start_at&.to_datetime, end_at&.to_datetime) }.compact
  end
end
