class AddBrcaNumberToBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :des_event_bookings, :brca_membership_number, :string
  end
end
