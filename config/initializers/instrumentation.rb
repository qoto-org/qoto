# frozen_string_literal: true

instrumentation_hostname = ENV.fetch('INSTRUMENTATION_HOSTNAME') { 'localhost' }

ActiveSupport::Notifications.subscribe(/process_action.action_controller/) do |*args|
  event      = ActiveSupport::Notifications::Event.new(*args)
  controller = event.payload[:controller]
  action     = event.payload[:action]
  format     = event.payload[:format] || 'all'
  format     = 'all' if format == '*/*'
  status     = event.payload[:status]
  key        = "#{controller}.#{action}.#{format}.#{instrumentation_hostname}"

  ActiveSupport::Notifications.instrument :performance, action: :measure, measurement: "#{key}.total_duration", value: event.duration
  ActiveSupport::Notifications.instrument :performance, action: :measure, measurement: "#{key}.db_time", value: event.payload[:db_runtime]
  ActiveSupport::Notifications.instrument :performance, action: :measure, measurement: "#{key}.view_time", value: event.payload[:view_runtime]
  ActiveSupport::Notifications.instrument :performance, measurement: "#{key}.status.#{status}"
end

EXPIRE_AFTER = 2.days.seconds.freeze

ActiveSupport::Notifications.subscribe(/activitypub.(ingress|egress)/) do |*args|
  event   = ActiveSupport::Notifications::Event.new(*args)
  buckets = [event.started.to_i % 3_600, event.started.to_i % 86_400]

  case event.name
  when 'activitypub.ingress'
    buckets.each do |bucket|
      Redis.current.hincrby("counters:activitypub.ingress:#{bucket}", "domain:#{event.payload[:domain]}", 1)
      Redis.current.hincrby("counters:activitypub.ingress:#{bucket}", "ip:#{event.payload[:ip]}", 1)
      Redis.current.expire("counters:activitypub.ingress:#{bucket}", EXPIRE_AFTER)
    end
  when 'activitypub.egress'
    buckets.each do |bucket|
      Redis.current.hincrby("counters:activitypub.egress:#{bucket}", "domain:#{event.payload[:domain]}", 1)
      Redis.current.expire("counters:activitypub.egress:#{bucket}", EXPIRE_AFTER)
    end
  end
end

def anomalies
  now = Time.now.to_i

  [3_600, 86_400].each do |interval|
    current_period = Redis.current.hgetall("counters:activitypub.ingress:#{now % interval}")
    past_period    = Redis.current.hgetall("counters:activitypub.ingress:#{now % interval - interval}")

    current_period.each_pair do |key, value|
      if value > past_period[key]
        # Sound the alarm!
      end
    end
  end
end
