# == Schema Information
#
# Table name: tag_follows
#
#  id         :bigint(8)        not null, primary key
#  tag_id     :bigint(8)        not null
#  account_id :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class TagFollow < ApplicationRecord
  include RateLimitable

  belongs_to :tag
  belongs_to :account

  rate_limit by: :account, family: :follows
end
