class CreateAdminWebhooks < ActiveRecord::Migration[6.1]
  def change
    create_table :admin_webhooks do |t|
      t.string :url, null: false, index: { unique: true }
      t.string :events, array: true, null: false, default: []
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end
  end
end
