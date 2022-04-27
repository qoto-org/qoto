# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  Redis.current = RedisConfiguration.new.connection
end
