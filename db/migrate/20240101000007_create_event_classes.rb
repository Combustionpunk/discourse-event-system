class CreateEventClasses < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_classes do |t|
      t.integer :event_id, null: false
      t.integer :class_type_id
      t.string :name, null: false
      t.integer :capacity, null: false
      t.string :status, default: 'active'
      t.timestamps
    end

    add_index :des_event_classes, :event_id
    add_index :des_event_classes, :class_type_id
  end
end
