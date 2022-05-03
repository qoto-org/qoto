# frozen_string_literal: true

# == Schema Information
#
# Table name: trends_filtered_trending_statuses
#
#  id         :bigint(8)
#  account_id :bigint(8)
#  allowed    :boolean
#  score      :float
#  language   :string
#

class Trends::FilteredTrendingStatus < Trends::TrendingStatus
  def readonly?
    true
  end
end
