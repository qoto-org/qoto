# frozen_string_literal: true

class Admin::Measure::BaseMeasure
  def initialize(start_at, end_at)
    @start_at = start_at
    @end_at   = end_at
  end

  def key
    raise NotImplementedError
  end

  def total
    raise NotImplementedError
  end

  def previous_total
    raise NotImplementedError
  end

  def data
    raise NotImplementedError
  end

  def self.model_name
    self.class.name
  end

  def read_attribute_for_serialization(key)
    send(key) if respond_to?(key)
  end
end
