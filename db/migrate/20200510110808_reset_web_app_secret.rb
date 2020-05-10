class ResetWebAppSecret < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    web_app = Doorkeeper::Application.find_by!(superapp: true)
    web_app.renew_secret
    web_app.save!
  end

  def down
  end
end
