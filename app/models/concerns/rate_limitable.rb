# frozen_string_literal: true

module RateLimitable
  extend ActiveSupport::Concern

  def rate_limiter(options = {})
    return @rate_limiter if defined?(@rate_limiter)

    @rate_limiter = RateLimiter.new(options)
  end

  def rate_limit_recorded!
    @rate_limit_recorded = true
  end

  def rate_limit_recorded?
    @rate_limit_recorded
  end

  class_methods do
    def rate_limit(options = {})
      self.after_create do
        by = public_send(options[:by])

        if by&.local?
          rate_limiter(options).record!
          rate_limit_recorded!
        end
      end

      self.after_rollback do
        rate_limiter(options).rollback! if rate_limit_recorded?
      end
    end
  end
end
