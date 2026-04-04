class RemoveUniqueConstraintFromBookings < ActiveRecord::Migration[7.0]
  def change
    remove_index :des_event_bookings, [:event_id, :user_id]
    add_index :des_event_bookings, [:event_id, :user_id]
  end
end
