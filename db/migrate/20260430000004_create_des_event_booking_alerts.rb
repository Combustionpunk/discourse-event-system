# frozen_string_literal: true

class CreateDesEventBookingAlerts < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_booking_alerts do |t|
      t.integer :user_id, null: false
      t.integer :event_id, null: false
      t.timestamps
    end
    add_index :des_event_booking_alerts, [:user_id, :event_id], unique: true
    add_index :des_event_booking_alerts, :event_id
  end
end
