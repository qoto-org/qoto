# frozen_string_literal: true

class Maintenance::RedownloadMediaWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', retry: false

  def perform(media_attachment_id)
    media = media_attachment_id.is_a?(MediaAttachment) ? media_attachment_id : MediaAttachment.find(media_attachment_id)

    return if media.remote_url.blank?

    media.reset_file!
    media.save
  rescue ActiveRecord::RecordNotFound
    true
  end
end
