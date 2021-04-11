# frozen_string_literal: true

class Web::PushNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'push', retry: 5

  TTL     = 48.hours.to_s
  URGENCY = 'normal'

  def perform(subscription_id, notification_id)
    @subscription = Web::PushSubscription.find(subscription_id)
    @notification = Notification.find(notification_id)

    # Polymorphically associated activity could have been deleted
    # in the meantime, so we have to double-check before proceeding
    return unless @notification.activity.present? && @subscription.pushable?(@notification)

    payload = @subscription.encrypt(notification_json)

    request_pool.with(@subscription.audience) do |http_client|
      request = Request.new(:post, @subscription.endpoint, body: payload, http_client: http_client)

      request.add_headers(
        'Content-Type'     => 'application/octet-stream',
        'Ttl'              => TTL,
        'Urgency'          => URGENCY,
        'Content-Encoding' => 'aes128gcm',
        'Content-Length'   => payload.size.to_s,
        'Authorization'    => @subscription.authorization_header,
      )

      request.perform do |response|
        # If the server responds with an error in the 4xx range
        # that isn't about rate-limiting or timeouts, we can
        # assume that the subscription is invalid or expired
        # and must be removed

        if (400..499).cover?(code) && ![408, 429].include?(code)
          @subscription.destroy!
        elsif !(200...300).cover?(response.code)
          raise Mastodon::UnexpectedResponseError, response
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    true
  end

  private

  def notification_json
    I18n.with_locale(@subscription.locale || I18n.default_locale) do
      ActiveModelSerializers::SerializableResource.new(
        @notification,
        serializer: Web::NotificationSerializer,
        scope: @subscription,
        scope_name: :current_push_subscription
      ).as_json
    end
  end

  def request_pool
    RequestPool.current
  end
end
