# frozen_string_literal: true

# == Schema Information
#
# Table name: admin_webhooks
#
#  id         :bigint(8)        not null, primary key
#  url        :string           not null
#  events     :string           default([]), not null, is an Array
#  enabled    :boolean          default(TRUE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Admin::Webhook < ApplicationRecord
  EVENTS = %w(
    report.created
  ).freeze

  validates :url, presence: true, url: true

  validate :validate_events

  private

  def validate_events
    errors.add(:events, :invalid) if events.any? { |e| !EVENTS.include?(e) }
  end
end
