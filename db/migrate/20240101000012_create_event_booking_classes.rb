class CreateEventBookingClasses < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_booking_classes do |t|
      t.integer :booking_id, null: false
      t.integer :event_class_id, null: false
      t.decimal :amount_charged, precision: 10, scale: 2, default: 0.0
      t.string :status, default: 'confirmed'
      t.string :transponder_number
      t.boolean :transponder_overridden, default: false
      t.timestamps
    end

    add_index :des_event_booking_classes, :booking_id
    add_index :des_event_booking_classes, :event_class_id
    add_index :des_event_booking_classes, [:booking_id, :event_class_id], 
              unique: true,
              name: 'unique_booking_class'
  end
end
