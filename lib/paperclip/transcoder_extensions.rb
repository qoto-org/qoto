# frozen_string_literal: true

module Paperclip
  module TranscoderExtensions
    # Prevent the transcoder from modifying our meta hash
    def initialize(file, options = {}, attachment = nil)
      meta_value = attachment.instance_read(:meta) if attachment
      super
      attachment.instance_write(:meta, meta_value) if attachment
    end
  end
end

Paperclip::Transcoder.prepend(Paperclip::TranscoderExtensions)
