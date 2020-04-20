# frozen_string_literal: true

class LocalNotificationWorker
  include Sidekiq::Worker

  def perform(receiver_account_id, activity_id = nil, activity_class_name = nil)
    if activity_id.nil? && activity_class_name.nil?
      activity = Mention.find(receiver_account_id)
      receiver = activity.account
    else
      receiver = Account.find(receiver_account_id)
      activity = activity_class_name.constantize.find(activity_id)
    end

    # This worker is only used for a few activity types, and they
    # happen to correspond to their class names
    type = activity_class_name.snake_case

    NotifyService.new.call(receiver, type, activity)
  rescue ActiveRecord::RecordNotFound
    true
  end
end
