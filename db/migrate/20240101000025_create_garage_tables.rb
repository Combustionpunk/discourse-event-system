class CreateGarageTables < ActiveRecord::Migration[7.0]
  def change
    # Drop old transponder table
    drop_table :des_user_transponders, if_exists: true

    # Manufacturers
    create_table :des_manufacturers do |t|
      t.string :name, null: false
      t.string :status, default: 'approved'
      t.integer :created_by
      t.timestamps
    end
    add_index :des_manufacturers, :name, unique: true
    add_index :des_manufacturers, :status

    # Car models
    create_table :des_car_models do |t|
      t.integer :manufacturer_id, null: false
      t.string :name, null: false
      t.integer :year_released
      t.string :status, default: 'approved'
      t.integer :created_by
      t.timestamps
    end
    add_index :des_car_models, :manufacturer_id
    add_index :des_car_models, :status

    # User garage
    create_table :des_user_cars do |t|
      t.integer :user_id, null: false
      t.integer :manufacturer_id, null: false
      t.integer :car_model_id
      t.integer :class_type_id
      t.string :driveline, null: false
      t.integer :year_released
      t.string :transponder_number
      t.string :friendly_name
      t.string :custom_model_name
      t.string :status, default: 'active'
      t.timestamps
    end
    add_index :des_user_cars, :user_id
    add_index :des_user_cars, :manufacturer_id

    # Class compatibility rules
    create_table :des_class_compatibility_rules do |t|
      t.integer :class_type_id, null: false
      t.string :rule_type, null: false
      t.string :rule_value, null: false
      t.timestamps
    end
    add_index :des_class_compatibility_rules, :class_type_id
  end
end
