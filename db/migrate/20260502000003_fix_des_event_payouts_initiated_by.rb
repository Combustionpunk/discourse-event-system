# frozen_string_literal: true

class FixDesEventPayoutsInitiatedBy < ActiveRecord::Migration[7.0]
  def change
    # Make initiated_by nullable since new payout system doesn't use it
    if column_exists?(:des_event_payouts, :initiated_by)
      change_column_null :des_event_payouts, :initiated_by, true
    end
    # Also make paypal_payout_id nullable if it exists
    if column_exists?(:des_event_payouts, :paypal_payout_id)
      change_column_null :des_event_payouts, :paypal_payout_id, true
    end
  end
end
