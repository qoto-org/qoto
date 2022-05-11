# frozen_string_literal: true

class DistributionWorker
  include Sidekiq::Worker
  include Redisable
  include Lockable

  def perform(status_id, options = {})
    with_lock("distribute:#{status_id}", autorelease: 5.minutes) do
      FanOutOnWriteService.new.call(Status.find(status_id), **options.symbolize_keys)
    end
  rescue ActiveRecord::RecordNotFound
    true
  end
end
