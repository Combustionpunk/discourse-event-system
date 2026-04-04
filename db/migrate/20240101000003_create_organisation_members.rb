class CreateOrganisationMembers < ActiveRecord::Migration[7.0]
  def change
    create_table :des_organisation_members do |t|
      t.integer :organisation_id, null: false
      t.integer :user_id, null: false
      t.integer :position_id, null: false
      t.string :status, default: 'active'
      t.timestamps
    end

    add_index :des_organisation_members, :organisation_id
    add_index :des_organisation_members, :user_id
    add_index :des_organisation_members, [:organisation_id, :user_id, :position_id], 
              unique: true,
              name: 'unique_org_member_position'
  end
end
