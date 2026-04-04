class CreateEventBookings < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_bookings do |t|
      t.integer :event_id, null: false
      t.integer :user_id, null: false
      t.string :status, default: 'pending'
      t.string :paypal_order_id
      t.decimal :total_amount, precision: 10, scale: 2, default: 0.0
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0.0
      t.decimal :amount_paid, precision: 10, scale: 2, default: 0.0
      t.timestamps
    end

    add_index :des_event_bookings, :event_id
    add_index :des_event_bookings, :user_id
    add_index :des_event_bookings, :status
    add_index :des_event_bookings, [:event_id, :user_id], unique: true
  end
end
