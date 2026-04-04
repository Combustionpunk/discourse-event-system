class CreateEventCancellationRefunds < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_cancellation_refunds do |t|
      t.integer :event_id, null: false
      t.integer :initiated_by, null: false
      t.integer :total_bookings, default: 0
      t.integer :total_refunded, default: 0
      t.integer :total_failed, default: 0
      t.decimal :total_amount_refunded, precision: 10, scale: 2, default: 0.0
      t.string :status, default: 'processing'
      t.timestamps
    end

    add_index :des_event_cancellation_refunds, :event_id, unique: true
    add_index :des_event_cancellation_refunds, :status
  end
end
