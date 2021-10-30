# frozen_string_literal: true

class Trends::Links
  PREFIX               = 'trending_links'
  EXPIRE_HISTORY_AFTER = 2.days.seconds

  include Redisable

  def add(link_id, account_id)
    increment_unique_use!(link_id, account_id)
    increment_use!(link_id)
  end

  def get(limit, filtered: true)
    link_ids = redis.zrevrange(PREFIX, 0, -1).map(&:to_i)

    preview_cards = PreviewCard.where(id: link_ids)
                               .where(type: :link)
                               .index_by(&:id)

    link_ids.map { |link_id| preview_cards[link_id] }
            .compact
            .take(limit)
  end

  def calculate(time = Time.now.utc)
    link_ids = (redis.smembers("#{PREFIX}:used:#{time.beginning_of_day.to_i}") + redis.zrange(PREFIX, 0, -1)).uniq

    link_ids.each do |link_id|
      expected  = redis.pfcount("activity:links:#{link_id}:#{(time - 1.day).beginning_of_day.to_i}:accounts").to_f
      expected  = 1.0 if expected.zero?
      observed  = redis.pfcount("activity:links:#{link_id}:#{time.beginning_of_day.to_i}:accounts").to_f

      score = begin
        if expected > observed
          0
        else
          ((observed - expected)**2) / expected
        end
      end

      if score.zero?
        redis.zrem(PREFIX, link_id)
      else
        redis.zadd(PREFIX, score, link_id)
      end
    end

    redis.zremrangebyscore(PREFIX, '(0.3', '-inf')
  end

  private

  def increment_use!(link_id, time = Time.now.utc)
    key = "#{PREFIX}:used:#{time.beginning_of_day.to_i}"

    redis.sadd(key, link_id)
    redis.expire(key, EXPIRE_HISTORY_AFTER)
  end

  def increment_unique_use!(link_id, account_id, time = Time.now.utc)
    key = "activity:links:#{link_id}:#{time.beginning_of_day.to_i}:accounts"

    redis.pfadd(key, account_id)
    redis.expire(key, EXPIRE_HISTORY_AFTER)
  end
end
