# frozen_string_literal: true

module Lockable
  def with_lock(lock_name, expire_after: 15.minutes, raise_on_failure: true)
    with_redis do |redis|
      RedisLock.acquire(redis: redis, key: lock_name, autorelease: expire_after.seconds, retry: false) do |lock|
        if lock.acquired?
          yield
        elsif raise_on_failure
          raise Mastodon::RaceConditionError, "Could not acquire lock for #{lock_name}, try again later"
        end
      end
    end
  end
end
