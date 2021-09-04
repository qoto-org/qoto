# frozen_string_literal: true

class UpdateStatusService < BaseService
  include Redisable

  def call(status, options = {})
    @status  = status
    @options = options

    Status.transaction do
      update_media_attachments!
      update_poll!
      update_immediate_attributes!
    end

    reset_preview_card!
    update_metadata!
    broadcast_updates!

    @status
  end

  private

  def update_media_attachments!
    previous_media_attachments = @status.media_attachments

    if @options[:media_ids].blank? || !@options[:media_ids].is_a?(Enumerable)
      previous_media_attachments.destroy_all
    else
      new_media_attachments      = validate_media!
      detached_media_attachments = previous_media_attachments - new_media_attachments

      detached_media_attachments.update_all(status_id: nil)
      new_media_attachments.update_all(status_id: @status.id)
    end
  end

  def validate_media!
    raise Mastodon::ValidationError, I18n.t('media_attachments.validations.too_many') if @options[:media_ids].size > 4 || @options[:poll].present?

    media_attachments = @account.media_attachments.where(status_id: [nil, @status.id]).where(id: @options[:media_ids].take(4).map(&:to_i)).to_a

    raise Mastodon::ValidationError, I18n.t('media_attachments.validations.images_and_video') if media_attachments.size > 1 && media_attachments.find(&:audio_or_video?)
    raise Mastodon::ValidationError, I18n.t('media_attachments.validations.not_ready') if media_attachments.any?(&:not_processed?)

    media_attachments
  end

  def update_poll!
    previous_poll = @status.poll

    if @options[:poll].blank?
      previous_poll&.destroy
    elsif previous_poll.present? && previous_poll.options == @options[:poll][:options]
      previous_poll.hides_totals = @options[:poll][:hide_totals]
      previous_poll.multiple = @options[:poll][:multiple]
      previous_poll.expires_in = @options[:poll][:expires_in]
    else
      previous_poll&.destroy
      @status.build_poll(@options[:poll])
    end
  end

  def update_immediate_attributes!
    @status.text         = @options[:text].presence || @options.delete(:spoiler_text)
    @status.spoiler_text = @options[:spoiler_text] || ''
    @status.language     = language_from_option || @status.language
  end

  def language_from_option
    ISO_639.find(@options[:language])&.alpha2
  end

  def reset_preview_card!
    @status.preview_cards.clear if @status.text_previously_changed?
    LinkCrawlWorker.perform_async(@status.id) if @status.spoiler_text.blank?
  end

  def update_metadata!
    ProcessHashtagsService.new.call(@status)
    ProcessMentionsService.new.call(@status)
  end

  def broadcast_updates!
    ActivityPub::DistributionWorker.perform_async(@status.id)
    PollExpirationNotifyWorker.perform_at(@status.poll.expires_at, @status.poll.id) if @status.poll
  end
end
