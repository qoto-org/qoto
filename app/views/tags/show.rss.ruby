RSSBuilder.build do |doc|
  doc.title("##{@tag.name}")
  doc.description(strip_tags(I18n.t('about.about_hashtag_html', hashtag: @tag.name)))
  doc.link(tag_url(@tag))
  doc.logo(full_pack_url('media/images/logo.svg'))
  doc.accent_color('2b90d9')
  doc.last_build_date(@statuses.first.created_at) if @statuses.any?

  @statuses.each do |status|
    doc.item do |item|
      item.title(l(status.created_at))
      item.link(ActivityPub::TagManager.instance.url_for(status))
      item.pub_date(status.created_at)
      item.description(rss_status_content_format(status))

      status.ordered_media_attachments.each do |media|
        item.enclosure(full_asset_url(media.file.url(:original, false)), media.file.content_type, media.file.size)

        item.media_group do |media_group|
          media_group.content(full_asset_url(media.file.url(:original, false)), media.file.content_type, media.file.size)
          media_group.rating(status.sensitive? ? 'adult' : 'nonadult')
          media_group.description(media.description) if media.description.present?
        end
      end

      status.tags.each do |tag|
        item.category(tag.name)
      end
    end
  end
end
