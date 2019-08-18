# frozen_string_literal: true

class ActivityPub::MentionSerializer < ActivityPub::Serializer
  attributes :type, :href, :name

  def type
    'Mention'
  end

  def href
    ActivityPub::TagManager.instance.uri_for(object)
  end

  def name
    "@#{object.acct}"
  end
end
