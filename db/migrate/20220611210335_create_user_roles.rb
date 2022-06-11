class CreateUserRoles < ActiveRecord::Migration[6.1]
  def change
    create_table :user_roles do |t|
      t.string :name, null: false, default: ''
      t.string :color, null: false, default: ''
      t.bigint :permissions, null: false, default: 0

      t.timestamps
    end
  end
end
