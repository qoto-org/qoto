# frozen_string_literal: true

module Paperclip
  module AttachmentExtensions
    # We overwrite this method to support delayed processing in
    # Sidekiq. Since we process the original file to reduce disk
    # usage, and we still want to generate thumbnails straight
    # away, it's the only style we need to exclude
    def process_style?(style_name, style_args)
      if style_name == :original && instance.respond_to?(:delay_processing?) && instance.delay_processing?
        false
      else
        style_args.empty? || style_args.include?(style_name)
      end
    end
  end
end

Paperclip::Attachment.prepend(Paperclip::AttachmentExtensions)
