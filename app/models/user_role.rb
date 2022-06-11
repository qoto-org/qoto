# frozen_string_literal: true

# == Schema Information
#
# Table name: user_roles
#
#  id          :bigint(8)        not null, primary key
#  name        :string           default(""), not null
#  color       :string           default(""), not null
#  permissions :bigint(8)        default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class UserRole < ApplicationRecord
  validates :name, :color, presence: true

  FLAGS = {
    administrator: (1 << 0),
    view_devops: (1 << 1),
    manage_reports: (1 << 2),
    manage_accounts: (1 << 3),
    manage_federation: (1 << 4),
    manage_settings: (1 << 5),
    manage_blocks: (1 << 6),
    manage_taxonomies: (1 << 7),
    manage_appeals: (1 << 8),
  }.freeze

  def self.nil_role
    @nil_role ||= UserRole.new
  end

  def permissions_as_hex
    '0x%016x' % permissions
  end

  def can?(privilege)
    raise ArgumentError, 'Unknown privilege' unless FLAGS.key?(privilege)

    return true if permissions & FLAGS[:administrator] == FLAGS[:administrator]

    permissions & FLAGS[privilege] == FLAGS[privilege]
  end

  def can!(privilege)
    raise ArgumentError, 'Unknown privilege' unless FLAGS.key?(privilege)

    permissions |= FLAGS[privilege]
  end
end
