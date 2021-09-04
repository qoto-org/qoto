# frozen_string_literal: true

class ActivityPub::DistributionWorker
  include Sidekiq::Worker
  include Payloadable

  sidekiq_options queue: 'push'

  def perform(status_id)
    @status  = Status.find(status_id)
    @account = @status.account

    ActivityPub::DeliveryWorker.push_bulk(inboxes) do |inbox_url|
      [payload, @account.id, inbox_url, { synchronize_followers: !@status.distributable? }]
    end
  rescue ActiveRecord::RecordNotFound
    true
  end

  private

  def inboxes
    @inboxes ||= StatusReachFinder.new(@status).inboxes
  end

  def payload
    @payload ||= Oj.dump(serialize_payload(ActivityPub::ActivityPresenter.from_status(@status), ActivityPub::ActivitySerializer, signer: @account))
  end
end
