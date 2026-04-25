class CreateDesEventResults < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_results do |t|
      t.integer :event_id, null: false
      t.string :status, null: false, default: 'pending'
      t.datetime :imported_at
      t.timestamps
    end
    add_index :des_event_results, :event_id, unique: true
  end
end
