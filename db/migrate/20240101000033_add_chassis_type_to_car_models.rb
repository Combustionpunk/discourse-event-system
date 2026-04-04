class AddChassisTypeToCarModels < ActiveRecord::Migration[7.0]
  def change
    add_column :des_car_models, :chassis_type, :string
  end
end
