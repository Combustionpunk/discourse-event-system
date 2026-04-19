class AddCarIdToBookingClasses < ActiveRecord::Migration[7.0]
  def change
    add_column :des_event_booking_classes, :car_id, :integer
    add_index :des_event_booking_classes, :car_id
  end
end
