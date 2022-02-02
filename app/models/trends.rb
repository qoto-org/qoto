# frozen_string_literal: true

module Trends
  def self.table_name_prefix
    'trends_'
  end

  def self.links
    @links ||= Trends::Links.new
  end

  def self.tags
    @tags ||= Trends::Tags.new
  end

  def self.statuses
    @statuses ||= Trends::Statuses.new
  end

  def self.register!(status)
    [links, tags, statuses].each { |trend_type| trend_type.register(status) }
  end

  def self.refresh!
    [links, tags, statuses].each(&:refresh)
  end

  def self.request_review!
    [links, tags, statuses].each(&:request_review) if enabled?
  end

  def self.enabled?
    Setting.trends
  end
end
