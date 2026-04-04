class MakeDrivelineNullableOnUserCars < ActiveRecord::Migration[7.0]
  def change
    change_column_null :des_user_cars, :driveline, true
  end
end
