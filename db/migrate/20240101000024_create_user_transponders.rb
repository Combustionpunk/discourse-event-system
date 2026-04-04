class CreateUserTransponders < ActiveRecord::Migration[7.0]
  def change
    create_table :des_user_transponders do |t|
      t.integer :user_id, null: false
      t.integer :class_type_id, null: false
      t.string :transponder_number, null: false
      t.timestamps
    end

    add_index :des_user_transponders, :user_id
    add_index :des_user_transponders, [:user_id, :class_type_id], unique: true, name: 'unique_user_class_transponder'
  end
end
