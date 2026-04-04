class CreateEventBookingRefunds < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_booking_refunds do |t|
      t.integer :booking_id, null: false
      t.integer :payment_id, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :reason
      t.string :status, default: 'pending'
      t.string :paypal_refund_id
      t.boolean :event_cancellation, default: false
      t.integer :initiated_by, null: false
      t.timestamps
    end

    add_index :des_event_booking_refunds, :booking_id
    add_index :des_event_booking_refunds, :payment_id
    add_index :des_event_booking_refunds, :status
  end
end
