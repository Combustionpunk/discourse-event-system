class AddDiscountsToPricingRules < ActiveRecord::Migration[7.0]
  def change
    add_column :des_event_pricing_rules, :member_first_class_discount, :decimal, precision: 10, scale: 2, null: true
    add_column :des_event_pricing_rules, :member_subsequent_discount, :decimal, precision: 10, scale: 2, null: true
    add_column :des_event_pricing_rules, :junior_first_class_discount, :decimal, precision: 10, scale: 2, null: true
    add_column :des_event_pricing_rules, :junior_subsequent_discount, :decimal, precision: 10, scale: 2, null: true
  end
end
