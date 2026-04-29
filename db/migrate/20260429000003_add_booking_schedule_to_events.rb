# frozen_string_literal: true

class AddBookingScheduleToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :des_events, :booking_opens_days_before, :integer
    add_column :des_events, :booking_closes_days_before, :integer
    add_column :des_events, :booking_manually_closed, :boolean, default: false
    add_column :des_events, :booking_manually_open, :boolean, default: false
  end
end
