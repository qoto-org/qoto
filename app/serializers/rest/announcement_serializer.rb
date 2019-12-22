# frozen_string_literal: true

class REST::AnnouncementSerializer < ActiveModel::Serializer
  attributes :id, :content, :starts_at, :ends_at

  def id
    object.id.to_s
  end

  def content
    Formatter.instance.linkify(object.text)
  end
end
