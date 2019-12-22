# frozen_string_literal: true

class Announcement < ApplicationRecord
  scope :live, ->(now = Time.now.utc) { where(arel_table[:scheduled_at].lteq(now)).where(arel_table[:ends_at].eq(nil).or(arel_table[:ends_at].gteq(now))) }
end
