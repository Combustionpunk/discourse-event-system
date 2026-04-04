class CreateMembershipPayments < ActiveRecord::Migration[7.0]
  def change
    create_table :des_membership_payments do |t|
      t.integer :membership_id, null: false
      t.integer :user_id, null: false
      t.integer :organisation_id, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.decimal :surcharge_percentage, precision: 5, scale: 2, default: 0.0
      t.string :status, default: 'pending'
      t.string :paypal_order_id
      t.string :paypal_capture_id
      t.timestamps
    end

    add_index :des_membership_payments, :membership_id
    add_index :des_membership_payments, :user_id
    add_index :des_membership_payments, :organisation_id
    add_index :des_membership_payments, :status
  end
end
