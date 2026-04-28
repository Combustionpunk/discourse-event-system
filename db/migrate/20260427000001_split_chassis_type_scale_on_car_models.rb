# frozen_string_literal: true

class SplitChassisTypeScaleOnCarModels < ActiveRecord::Migration[7.0]
  def up
    add_column :des_car_models, :scale, :string

    # Auto-split existing chassis_type values into scale + chassis_type
    # e.g. "1/10 Buggy" -> scale: "1/10", chassis_type: "Buggy"
    execute <<-SQL
      UPDATE des_car_models
      SET
        scale = SPLIT_PART(chassis_type, ' ', 1),
        chassis_type = TRIM(SUBSTRING(chassis_type FROM POSITION(' ' IN chassis_type) + 1))
      WHERE chassis_type IS NOT NULL AND chassis_type LIKE '%/%  %'
        OR chassis_type LIKE '% %'
    SQL
  end

  def down
    remove_column :des_car_models, :scale
  end
end
