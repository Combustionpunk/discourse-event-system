class AddBookingClosingDateToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :des_events, :booking_closing_date, :datetime
  end
end
