class CreateEventDiscounts < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_discounts do |t|
      t.integer :event_id, null: false
      t.string :name, null: false
      t.string :discount_type, null: false
      t.decimal :value, precision: 10, scale: 2, null: false
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :des_event_discounts, :event_id
  end
end
