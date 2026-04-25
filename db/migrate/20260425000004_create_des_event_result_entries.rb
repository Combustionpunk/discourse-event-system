class CreateDesEventResultEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_result_entries do |t|
      t.integer :race_id, null: false
      t.integer :position
      t.string :driver_name
      t.string :car_number
      t.integer :laps
      t.string :race_time
      t.string :best_lap
      t.integer :user_id
      t.boolean :match_confirmed, default: false
      t.timestamps
    end
    add_index :des_event_result_entries, :race_id
    add_index :des_event_result_entries, :user_id
  end
end
