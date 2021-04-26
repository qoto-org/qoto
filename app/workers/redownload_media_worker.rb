# frozen_string_literal: true

class RedownloadMediaWorker
  include Sidekiq::Worker
  include ExponentialBackoff

  sidekiq_options queue: 'pull', retry: 3

  def perform(id)
    media_attachment = MediaAttachment.find(id)

    return if media_attachment.remote_url.blank?

    media_attachment.download_file!
    media_attachment.download_thumbnail!
    media_attachment.save
  rescue ActiveRecord::RecordNotFound, Mastodon::UnexpectedResponseError
    # We mainly retry connection/timeout errors. If a static file
    # returns an unexpected response code, there is in most cases
    # no sense in retrying
  end
end
