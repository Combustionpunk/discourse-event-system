class AddDrivelineToCarModels < ActiveRecord::Migration[7.0]
  def change
    add_column :des_car_models, :driveline, :string
  end
end
