# frozen_string_literal: true

class AddScalePowerToClassTypes < ActiveRecord::Migration[7.0]
  def up
    unless column_exists?(:des_event_class_types, :scale)
      add_column :des_event_class_types, :scale, :string
    end

    unless column_exists?(:des_event_class_types, :power_type)
      add_column :des_event_class_types, :power_type, :string
    end

    # Set all existing class types to 1/10 electric
    execute("UPDATE des_event_class_types SET scale = '1/10', power_type = 'electric'")

    # Set all existing car models to electric (scale already set per record)
    execute("UPDATE des_car_models SET power_type = 'electric' WHERE power_type IS NULL OR power_type = ''")

    # Set scale on car models that don't have it set
    execute("UPDATE des_car_models SET scale = '1/10' WHERE scale IS NULL OR scale = ''")
  end

  def down
    remove_column :des_event_class_types, :power_type if column_exists?(:des_event_class_types, :power_type)
    remove_column :des_event_class_types, :scale if column_exists?(:des_event_class_types, :scale)
  end
end
