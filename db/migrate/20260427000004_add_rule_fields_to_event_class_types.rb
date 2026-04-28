# frozen_string_literal: true

class AddRuleFieldsToEventClassTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :des_event_class_types, :min_year, :integer
    add_column :des_event_class_types, :max_year, :integer
    add_column :des_event_class_types, :manufacturer, :string
    add_column :des_event_class_types, :model_id, :integer
    add_column :des_event_class_types, :min_age, :integer
    add_column :des_event_class_types, :max_age, :integer
  end
end
