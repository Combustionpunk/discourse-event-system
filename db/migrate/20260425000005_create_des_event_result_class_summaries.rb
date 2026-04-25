class CreateDesEventResultClassSummaries < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_result_class_summaries do |t|
      t.integer :event_result_id, null: false
      t.string :class_name
      t.integer :first_user_id
      t.integer :second_user_id
      t.integer :third_user_id
      t.string :first_driver_name
      t.string :second_driver_name
      t.string :third_driver_name
      t.integer :fastest_lap_user_id
      t.string :fastest_lap_driver_name
      t.string :fastest_lap_time
      t.timestamps
    end
    add_index :des_event_result_class_summaries, :event_result_id
  end
end
