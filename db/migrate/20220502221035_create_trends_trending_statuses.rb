class CreateTrendsTrendingStatuses < ActiveRecord::Migration[6.1]
  def change
    create_table :trends_trending_statuses do |t|
      t.bigint :account_id, null: false
      t.boolean :allowed, null: false, default: false
      t.float :score, null: false, default: 0
      t.string :language
    end
  end
end
