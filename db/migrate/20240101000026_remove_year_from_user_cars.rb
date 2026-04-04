class RemoveYearFromUserCars < ActiveRecord::Migration[7.0]
  def change
    remove_column :des_user_cars, :year_released, :integer
  end
end
