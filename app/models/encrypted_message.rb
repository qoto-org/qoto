# frozen_string_literal: true
# == Schema Information
#
# Table name: encrypted_messages
#
#  id              :bigint(8)        not null, primary key
#  device_id       :bigint(8)
#  from_account_id :bigint(8)
#  type            :integer          default(0), not null
#  body            :text             default(""), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class EncryptedMessage < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :device
  belongs_to :from_account, class_name: 'Account'
end
