class CreateDesEventResultRaces < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_result_races do |t|
      t.integer :event_result_id, null: false
      t.string :round_name
      t.string :race_name
      t.string :class_name
      t.string :final_type
      t.integer :rc_results_race_id
      t.timestamps
    end
    add_index :des_event_result_races, :event_result_id
  end
end
