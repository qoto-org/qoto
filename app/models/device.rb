# frozen_string_literal: true
# == Schema Information
#
# Table name: devices
#
#  id              :bigint(8)        not null, primary key
#  access_token_id :bigint(8)
#  account_id      :bigint(8)
#  device_id       :string           default(""), not null
#  name            :string           default(""), not null
#  fingerprint     :text             default(""), not null
#  identity        :text             default(""), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Device < ApplicationRecord
  belongs_to :access_token, class_name: 'Doorkeeper::AccessToken'
  belongs_to :account

  has_many :one_time_keys, dependent: :destroy, inverse_of: :device
  has_many :encrypted_messages, dependent: :destroy, inverse_of: :device

  validates :name, :fingerprint, :identity, presence: true

  before_save :invalidate_associations, if: -> { fingerprint_changed? || identity_changed? }

  private

  def invalidate_associations
    one_time_keys.destroy_all
    encrypted_messages.destroy_all
  end
end
