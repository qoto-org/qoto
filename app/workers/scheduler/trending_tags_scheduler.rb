# frozen_string_literal: true

class Scheduler::TrendingTagsScheduler
  include Sidekiq::Worker

  sidekiq_options retry: 0

  def perform
    Trends.tags.calculate if Setting.trends
    Trends.links.calculate
  end
end
