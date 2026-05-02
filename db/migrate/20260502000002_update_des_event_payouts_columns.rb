# frozen_string_literal: true

class UpdateDesEventPayoutsColumns < ActiveRecord::Migration[7.0]
  def change
    # Add missing columns if they don't exist
    unless column_exists?(:des_event_payouts, :transaction_count)
      add_column :des_event_payouts, :transaction_count, :integer, default: 0
    end
    unless column_exists?(:des_event_payouts, :paypal_fee_percent)
      add_column :des_event_payouts, :paypal_fee_percent, :decimal, precision: 5, scale: 2, default: 0
    end
    unless column_exists?(:des_event_payouts, :paypal_fee_fixed)
      add_column :des_event_payouts, :paypal_fee_fixed, :decimal, precision: 5, scale: 2, default: 0
    end
    unless column_exists?(:des_event_payouts, :paypal_fee_amount)
      add_column :des_event_payouts, :paypal_fee_amount, :decimal, precision: 10, scale: 2, default: 0
    end
    unless column_exists?(:des_event_payouts, :surcharge_percent)
      add_column :des_event_payouts, :surcharge_percent, :decimal, precision: 5, scale: 2, default: 0
    end
    unless column_exists?(:des_event_payouts, :complimentary_count)
      add_column :des_event_payouts, :complimentary_count, :integer, default: 0
    end
    unless column_exists?(:des_event_payouts, :approved_by_user_id)
      add_column :des_event_payouts, :approved_by_user_id, :integer
    end
    unless column_exists?(:des_event_payouts, :approved_at)
      add_column :des_event_payouts, :approved_at, :datetime
    end
    unless column_exists?(:des_event_payouts, :claimed_at)
      add_column :des_event_payouts, :claimed_at, :datetime
    end
    unless column_exists?(:des_event_payouts, :paypal_email_snapshot)
      add_column :des_event_payouts, :paypal_email_snapshot, :string
    end
    unless column_exists?(:des_event_payouts, :paypal_payout_batch_id)
      add_column :des_event_payouts, :paypal_payout_batch_id, :string
    end
    unless column_exists?(:des_event_payouts, :paypal_payout_item_id)
      add_column :des_event_payouts, :paypal_payout_item_id, :string
    end
    unless column_exists?(:des_event_payouts, :failure_reason)
      add_column :des_event_payouts, :failure_reason, :string
    end
    unless column_exists?(:des_event_payouts, :currency)
      add_column :des_event_payouts, :currency, :string, default: 'GBP'
    end
    unless column_exists?(:des_event_payouts, :notes)
      add_column :des_event_payouts, :notes, :text
    end
    # Rename old columns if they exist with old names
    if column_exists?(:des_event_payouts, :surcharge_percentage) && !column_exists?(:des_event_payouts, :surcharge_percent)
      rename_column :des_event_payouts, :surcharge_percentage, :surcharge_percent
    end
  end
end
