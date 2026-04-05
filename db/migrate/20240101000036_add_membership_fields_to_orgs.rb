class AddMembershipFieldsToOrgs < ActiveRecord::Migration[7.0]
  def change
    add_column :des_organisations, :discourse_group_id, :integer, null: true
    add_column :des_organisation_memberships, :paypal_order_id, :string, null: true
    add_column :des_organisation_memberships, :paypal_capture_id, :string, null: true
    add_column :des_organisation_memberships, :amount_paid, :decimal, precision: 10, scale: 2, null: true
  end
end
