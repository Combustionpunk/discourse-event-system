class CreateEventBookingPayments < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_booking_payments do |t|
      t.integer :booking_id, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :paypal_order_id
      t.string :paypal_capture_id
      t.string :payment_type, default: 'initial'
      t.string :status, default: 'pending'
      t.timestamps
    end

    add_index :des_event_booking_payments, :booking_id
    add_index :des_event_booking_payments, :status
    add_index :des_event_booking_payments, :paypal_order_id
  end
end
