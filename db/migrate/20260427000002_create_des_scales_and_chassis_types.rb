# frozen_string_literal: true

class CreateDesScalesAndChassisTypes < ActiveRecord::Migration[7.0]
  def up
    create_table :des_scales do |t|
      t.string :name, null: false
      t.integer :position, default: 0
      t.timestamps
    end
    add_index :des_scales, :name, unique: true

    create_table :des_chassis_types do |t|
      t.string :name, null: false
      t.integer :position, default: 0
      t.timestamps
    end
    add_index :des_chassis_types, :name, unique: true

    # Seed with current values
    ['1/8', '1/10', '1/12', '1/28'].each_with_index do |name, i|
      execute "INSERT INTO des_scales (name, position, created_at, updated_at) VALUES ('#{name}', #{i}, NOW(), NOW())"
    end

    ['Buggy', 'Truck', 'Stadium', 'Short Course', 'Touring Car', 'Rally', 'Pan Car', 'Drift'].each_with_index do |name, i|
      execute "INSERT INTO des_chassis_types (name, position, created_at, updated_at) VALUES ('#{name}', #{i}, NOW(), NOW())"
    end
  end

  def down
    drop_table :des_scales
    drop_table :des_chassis_types
  end
end
