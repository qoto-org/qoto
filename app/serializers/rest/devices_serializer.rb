# frozen_string_literal: true

class REST::DevicesSerializer < ActiveModel::Serializer
  attributes :id

  has_many :devices

  def id
    object.id.to_s
  end

  class DeviceSerializer < ActiveModel::Serializer
    attributes :device_id, :name, :identity, :fingerprint

    def device_id
      "#{object.account.acct}:#{object.device_id}"
    end
  end
end
