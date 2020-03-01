# frozen_string_literal: true

class RateLimiter
  include Redisable

  def initialize(options = {})
    @by     = options[:by]
    @family = options[:family]
    @limit  = options[:limit]
    @period = options[:period].to_i
  end

  def record!
    count = redis.get(key)

    if count.nil?
      redis.set(key, 0)
      redis.expire(key, (@period - (last_epoch_time % @period) + 1).to_i)
    end

    if count > @limit
      raise Mastodon::RateLimitExceededError.new(@limit, @period)
    end

    redis.increment(key)
  end

  def rollback!
    redis.decrement(key)
  end

  private

  def key
    @key ||= "rate_limit:#{@by.id}:#{@family}:#{(last_epoch_time / @period).to_i}"
  end

  def last_epoch_time
    @last_epoch_time ||= Time.now.to_i
  end
end
