class CreateEventDiscountConditions < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_discount_conditions do |t|
      t.integer :discount_id, null: false
      t.string :condition_type, null: false
      t.string :condition_value, null: false
      t.timestamps
    end

    add_index :des_event_discount_conditions, :discount_id
  end
end
