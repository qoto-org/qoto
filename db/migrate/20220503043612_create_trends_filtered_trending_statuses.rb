class CreateTrendsFilteredTrendingStatuses < ActiveRecord::Migration[6.1]
  def change
    create_view :trends_filtered_trending_statuses
  end
end
