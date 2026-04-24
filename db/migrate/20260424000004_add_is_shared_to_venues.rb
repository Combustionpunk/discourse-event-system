class AddIsSharedToVenues < ActiveRecord::Migration[7.0]
  def change
    add_column :des_venues, :is_shared, :boolean, default: false
  end
end
