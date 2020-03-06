# frozen_string_literal: true

class PostProcessMediaWorker
  include Sidekiq::Worker

  def perform(media_attachment_id)
    media_attachment = MediaAttachment.find(media_attachment_id)
    media_attachment.processing = :in_progress
    media_attachment.save
    media_attachment.file.reprocess!
    media_attachment.processing = :complete
    media_attachment.save
  rescue Paperclip::Error
    media_attachment.processing = :failed
    media_attachment.save
  rescue ActiveRecord::RecordNotFound
    true
  end
end
