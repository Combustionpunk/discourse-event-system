class CreateOrganisationMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :des_organisation_memberships do |t|
      t.integer :organisation_id, null: false
      t.integer :user_id, null: false
      t.integer :membership_type_id, null: false
      t.string :status, default: 'active'
      t.datetime :starts_at, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :des_organisation_memberships, :organisation_id
    add_index :des_organisation_memberships, :user_id
    add_index :des_organisation_memberships, :status
    add_index :des_organisation_memberships, :expires_at
    add_index :des_organisation_memberships, [:organisation_id, :user_id],
              name: 'index_des_org_memberships_on_org_and_user'
  end
end
