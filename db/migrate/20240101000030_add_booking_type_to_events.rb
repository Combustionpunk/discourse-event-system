class AddBookingTypeToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :des_events, :booking_type, :string, default: 'internal'
    add_column :des_events, :external_booking_url, :string
    add_column :des_events, :external_booking_details, :text
  end
end
