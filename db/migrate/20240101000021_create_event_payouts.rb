class CreateEventPayouts < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_payouts do |t|
      t.integer :event_id, null: false
      t.integer :organisation_id, null: false
      t.decimal :gross_amount, precision: 10, scale: 2, default: 0.0
      t.decimal :surcharge_percentage, precision: 5, scale: 2, default: 0.0
      t.decimal :surcharge_amount, precision: 10, scale: 2, default: 0.0
      t.decimal :net_amount, precision: 10, scale: 2, default: 0.0
      t.string :status, default: 'pending'
      t.string :paypal_payout_id
      t.integer :initiated_by, null: false
      t.datetime :paid_at
      t.timestamps
    end

    add_index :des_event_payouts, :event_id, unique: true
    add_index :des_event_payouts, :organisation_id
    add_index :des_event_payouts, :status
  end
end
