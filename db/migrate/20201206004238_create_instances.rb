class CreateInstances < ActiveRecord::Migration[5.2]
  def change
    create_view :instances
  end
end
