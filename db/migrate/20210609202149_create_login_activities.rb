class CreateLoginActivities < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      execute <<~SQL
        CREATE TYPE authentication_method AS ENUM (
          'password',
          'otp',
          'webauthn',
          'sign_in_token',
          'omniauth'
        )
      SQL
    end

    create_table :login_activities do |t|
      t.belongs_to :user, null: false, foreign_key: { on_delete: :cascade }
      t.column :authentication_method, :authentication_method
      t.string :provider
      t.boolean :success
      t.string :failure_reason
      t.inet :ip
      t.string :user_agent
      t.datetime :created_at
    end
  end

  def down
    drop_table :login_activities

    safety_assured do
      execute <<~SQL
        DROP TYPE authentication_method
      SQL
    end
  end
end
