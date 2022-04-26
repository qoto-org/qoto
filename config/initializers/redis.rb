# frozen_string_literal: true

url       = ENV['REDIS_URL']
namespace = ENV.fetch('REDIS_NAMESPACE') { nil }
pool_size = ENV['REDIS_POOL'] || ENV['MAX_THREADS'] || 5

Redis.current = ConnectionPool::Wrapper.new(size: pool_size, timeout: 3) do
  connection = Redis.new(url: url, driver: :hiredis)

  if namespace
    Redis::Namespace.new(namespace, redis: connection)
  else
    connection
  end
end
