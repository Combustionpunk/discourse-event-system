# frozen_string_literal: true

class AddAttributesToEventClassTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :des_event_class_types, :track_environment, :string
    add_column :des_event_class_types, :scale, :string
    add_column :des_event_class_types, :chassis_types, :string
    add_column :des_event_class_types, :drivelines, :string
  end
end
