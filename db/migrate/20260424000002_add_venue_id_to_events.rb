class AddVenueIdToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :des_events, :venue_id, :integer
    add_index :des_events, :venue_id
  end
end
