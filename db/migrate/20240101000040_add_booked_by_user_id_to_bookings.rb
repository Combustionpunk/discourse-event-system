# frozen_string_literal: true

class AddBookedByUserIdToBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :des_event_bookings, :booked_by_user_id, :integer
    add_index :des_event_bookings, :booked_by_user_id
  end
end
