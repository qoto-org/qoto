# frozen_string_literal: true

class ActivityPub::Parser::MediaAttachmentParser
  include JsonLdHelper

  def initialize(json)
    @json = json
  end

  # @param [MediaAttachment] previous_record
  def significantly_changes?(previous_record)
    remote_url.presence != previous_record.remote_url.presence ||
      thumbnail_remote_url.presence != previous_record.thumbnail_remote_url.presence ||
      description.presence != previous_record.description.presence
  end

  def remote_url
    Addressable::URI.parse(@json['url'])&.normalize&.to_s
  rescue Addressable::URI::InvalidURIError
    nil
  end

  def thumbnail_remote_url
    Addressable::URI.parse(@json['icon'].is_a?(Hash) ? @json['icon']['url'] : @json['icon'])&.normalize&.to_s
  rescue Addressable::URI::InvalidURIError
    nil
  end

  def description
    str = @json['summary'].presence || @json['name'].presence
    str = str.strip[0...MAX_DESCRIPTION_LENGTH] if str.present?
    str
  end

  def focus
    @json['focalPoint']
  end

  def blurhash
    supported_blurhash? ? @json['blurhash'] : nil
  end

  def file_content_type
    @json['mediaType']
  end

  private

  def supported_blurhash?
    components = begin
      blurhash = @json['blurhash']

      if blurhash.present? && /^[\w#$%*+-.:;=?@\[\]^{|}~]+$/.match?(blurhash)
        Blurhash.components(blurhash)
      end
    end

    components.present? && components.none? { |comp| comp > 5 }
  end
end
