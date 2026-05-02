# frozen_string_literal: true

class CreateDesEventPayouts < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_payouts do |t|
      t.integer :event_id, null: false
      t.integer :organisation_id, null: false
      t.decimal :gross_amount, precision: 10, scale: 2, default: 0
      t.integer :transaction_count, default: 0
      t.decimal :paypal_fee_percent, precision: 5, scale: 2, default: 0
      t.decimal :paypal_fee_fixed, precision: 5, scale: 2, default: 0
      t.decimal :paypal_fee_amount, precision: 10, scale: 2, default: 0
      t.decimal :surcharge_percent, precision: 5, scale: 2, default: 0
      t.decimal :surcharge_amount, precision: 10, scale: 2, default: 0
      t.decimal :net_amount, precision: 10, scale: 2, default: 0
      t.integer :complimentary_count, default: 0
      t.string :status, default: 'pending'
      t.integer :approved_by_user_id
      t.datetime :approved_at
      t.datetime :claimed_at
      t.datetime :paid_at
      t.string :paypal_email_snapshot
      t.string :paypal_payout_batch_id
      t.string :paypal_payout_item_id
      t.string :failure_reason
      t.string :currency, default: 'GBP'
      t.text :notes
      t.timestamps
    end
    add_index :des_event_payouts, :event_id, unique: true
    add_index :des_event_payouts, :organisation_id
    add_index :des_event_payouts, :status
  end
end
