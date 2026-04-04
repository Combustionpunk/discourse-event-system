class CreateEventPricingRules < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_pricing_rules do |t|
      t.integer :event_id, null: false
      t.string :rule_type, null: false
      t.decimal :first_class_price, precision: 10, scale: 2
      t.decimal :subsequent_class_price, precision: 10, scale: 2
      t.decimal :flat_price, precision: 10, scale: 2
      t.timestamps
    end

    add_index :des_event_pricing_rules, :event_id, unique: true
  end
end
